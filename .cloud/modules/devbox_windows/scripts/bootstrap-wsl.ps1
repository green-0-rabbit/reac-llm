# PHASE 1 - runs as SYSTEM via CustomScript Extension
# Enables WSL features, installs VS Code, drops Phase 2 + toolchain
# scripts to disk, registers Active Setup for user-context execution,
# then reboots. Phase 2 runs as the interactive user at first logon.
$ErrorActionPreference="Stop"
$l="C:\WindowsAzure\Logs\bwsl.log"
function L($m){"$(Get-Date -f 'yyyy-MM-dd HH:mm:ss') $m"|Out-File $l -Append}
L "P1 START"

# VS Code (machine-wide silent install, direct download - winget unreliable under SYSTEM)
if(!(Test-Path "C:\Program Files\Microsoft VS Code\Code.exe")){
  $vscUrl="https://update.code.visualstudio.com/latest/win32-x64/stable"
  $vscExe="$env:TEMP\vscode-setup.exe"
  L "downloading vscode"
  $ErrorActionPreference="Continue"
  & curl.exe -fSL -o $vscExe $vscUrl 2>&1|Out-Null
  $ErrorActionPreference="Stop"
  L "installing vscode"
  Start-Process -Wait -FilePath $vscExe -ArgumentList '/verysilent','/mergetasks=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath'
  Remove-Item $vscExe -EA 0
  L "vscode installed"
}else{
  L "vscode exists"
}

# Enable WSL + VM-Platform features (need reboot to activate kernel)
dism /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart 2>&1|Out-Null
dism /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart 2>&1|Out-Null
L "features enabled"

$d="C:\bwsl";md $d -Force -EA 0|Out-Null

# toolchain.sh (executed inside WSL Ubuntu by Phase 2)
@'
set -ex
export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get install -y ca-certificates curl gnupg lsb-release unzip wget
curl -fsSL https://apt.releases.hashicorp.com/gpg|gpg --batch --yes --dearmor -o /usr/share/keyrings/hc.gpg
echo "deb [signed-by=/usr/share/keyrings/hc.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main">/etc/apt/sources.list.d/hc.list
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg|gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg
. /etc/os-release
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $VERSION_CODENAME stable">/etc/apt/sources.list.d/docker.list
apt-get update && apt-get install -y terraform docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
curl -fsSL https://deb.nodesource.com/setup_lts.x|bash -
apt-get install -y nodejs
npm i -g corepack && corepack enable && corepack prepare yarn@stable --activate
curl -sL https://aka.ms/InstallAzureCLIDeb|bash
curl --proto =https --tlsv1.2 -sSf https://just.systems/install.sh|bash -s -- --to /usr/local/bin --force
printf "[boot]\nsystemd=true\n">/etc/wsl.conf
'@|Set-Content "$d\tc.sh" -Encoding ASCII -Force

# Phase 2 PS1 (runs as interactive user via Active Setup)
# ASCII only - no special chars to avoid encoding issues
@'
$ErrorActionPreference="Continue"
$l="C:\bwsl\p2.log"
function L($m){"$(Get-Date -f 'HH:mm:ss') $m"|Out-File $l -Append -Force}
L "P2 START user=$env:USERNAME"

wsl --set-default-version 2 2>&1|Out-Null

function TU{$r=(wsl -l -q 2>&1)|Out-String;$r=$r -replace '\x00','';return $r -match 'Ubuntu'}

if(-not(TU)){
  L "installing Ubuntu (web-download)"
  wsl --install -d Ubuntu --web-download --no-launch 2>&1|Out-Null
  $j=0;while(-not(TU) -and $j++ -lt 60){Start-Sleep 5;L "waiting $j"}
}
if(-not(TU)){
  L "installing Ubuntu (fallback)"
  wsl --install -d Ubuntu --no-launch 2>&1|Out-Null
  $j=0;while(-not(TU) -and $j++ -lt 60){Start-Sleep 5;L "waiting2 $j"}
}
if(-not(TU)){L "FAIL - no Ubuntu distro";exit 1}
L "Ubuntu OK - running toolchain"

wsl -d Ubuntu -u root -- bash -c "sed 's/\r$//' /mnt/c/bwsl/tc.sh | bash" 2>&1|Out-Null
$ec=$LASTEXITCODE
if($ec -eq 0){
  L "DONE - toolchain installed"
}else{
  L "WARN exit=$ec - manual fix: wsl -d Ubuntu -u root -- bash -c 'sed s/\r$// /mnt/c/bwsl/tc.sh | bash'"
}
'@|Set-Content "$d\p2.ps1" -Encoding ASCII -Force
L "scripts written"

# Active Setup: runs ONCE per user at logon, in user context (not SYSTEM)
# This is how Windows itself handles per-user first-run initialization
$asKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{B5E6A7C3-9D2F-4A1B-8C0E-3F5D7A9B2E41}"
New-Item -Path $asKey -Force|Out-Null
Set-ItemProperty -Path $asKey -Name "(Default)" -Value "WSL Bootstrap Phase 2"
Set-ItemProperty -Path $asKey -Name "StubPath" -Value 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\bwsl\p2.ps1"'
Set-ItemProperty -Path $asKey -Name "Version" -Value "1,0,0,0"
L "Active Setup registered"

# Reboot to activate WSL kernel; Phase 2 fires at next user logon
shutdown /r /t 30 /c "WSL bootstrap reboot" /f
L "P1 DONE"
