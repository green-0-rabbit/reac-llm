const { DefaultAzureCredential, ManagedIdentityCredential } = require('@azure/identity');

async function main() {
  // Scope for Azure OSS RDBMS (PostgreSQL, MySQL, MariaDB)
  const scope = "https://ossrdbms-aad.database.windows.net/.default";
  const clientId = process.env.AZURE_CLIENT_ID;
  
  try {
    let credential;
    if (clientId) {
      // Use the specific User Assigned Identity if Client ID is provided
      console.error(`Using ManagedIdentityCredential with Client ID: ${clientId}`);
      credential = new ManagedIdentityCredential(clientId);
    } else {
      // Fallback to Default (might pick System Assigned)
      console.error('Using DefaultAzureCredential');
      credential = new DefaultAzureCredential();
    }

    const tokenResponse = await credential.getToken(scope);
    
    console.log(tokenResponse.token);
  } catch (err) {
    console.error('Failed to acquire Access Token:', err);
    process.exit(1);
  }
}

main();
