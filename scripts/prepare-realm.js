import Admin from '@keycloak/keycloak-admin-client';
import { Command } from 'commander';
import fs from 'fs/promises';
import path from 'path';

const program = new Command();

function omitProperties(obj, propertiesToOmit) {
  // Clone the object and delete the unwanted properties
  let objCopy = { ...obj };

  propertiesToOmit.forEach((prop) => {
    delete objCopy[prop];
  });
  // objCopy['clients'].filter((client)=>)

  return objCopy;
}

const setupClients = [];
const users = [];
// Properties to omit

const webAuthn = [
  'webAuthnPolicyRpEntityName',
  'webAuthnPolicySignatureAlgorithms',
  'webAuthnPolicyRpId',
  'webAuthnPolicyAttestationConveyancePreference',
  'webAuthnPolicyAuthenticatorAttachment',
  'webAuthnPolicyRequireResidentKey',
  'webAuthnPolicyUserVerificationRequirement',
  'webAuthnPolicyCreateTimeout',
  'webAuthnPolicyAvoidSameAuthenticatorRegister',
  'webAuthnPolicyAcceptableAaguids',
  'webAuthnPolicyPasswordlessRpEntityName',
  'webAuthnPolicyPasswordlessSignatureAlgorithms',
  'webAuthnPolicyPasswordlessRpId',
  'webAuthnPolicyPasswordlessAttestationConveyancePreference',
  'webAuthnPolicyPasswordlessAuthenticatorAttachment',
  'webAuthnPolicyPasswordlessRequireResidentKey',
  'webAuthnPolicyPasswordlessUserVerificationRequirement',
  'webAuthnPolicyPasswordlessCreateTimeout',
  'webAuthnPolicyPasswordlessAvoidSameAuthenticatorRegister',
  'webAuthnPolicyPasswordlessAcceptableAaguids',
];
const propertiesToOmit = [
  ...webAuthn,
  'clientScopeMappings',
  'scopeMappings',
  'defaultOptionalClientScopes',
  'defaultDefaultClientScopes',
  'components',
  'authenticationFlows',
  // 'authenticatorConfig',
  'requiredActions',
  'browserFlow',
  'registrationFlow',
  'directGrantFlow',
  'resetCredentialsFlow',
  'clientAuthenticationFlow',
  'dockerAuthenticationFlow',
  'clientScopes',
  'defaultRole',
  'defaultRoles',
];

async function main(clientSecret = '', realmName = '', outputFilePath = '') {
  try {
    const kcAdminClient = new Admin({
      baseUrl: 'http://localhost:8080',
      realmName: 'master',
    });
    await kcAdminClient.auth({
      grantType: 'password',
      clientId: 'admin-cli',
      username: 'admin',
      password: 'admin',
    });

    let realm = await kcAdminClient.realms.export({
      exportClients: true,
      exportGroupsAndRoles: true,
      realm: realmName,
      exportUsers: true,
    });

    if (!realm.users) {
        const users = await kcAdminClient.users.find({ realm: realmName });
        realm.users = users;
    }

    const {
      clients: oldClient,
      roles: oldRoles,
      users: oldUsers,
      ...compactedRealm
    } = omitProperties(realm, propertiesToOmit);

    const filteredClient = oldClient.filter(
      (client) =>
        !['realm-management', 'security-admin-console', 'admin-cli', 'broker', 'ci'].includes(
          client.clientId
        )
    );

    const modifiedClients = [...filteredClient, ...setupClients].map((client) => {
      if (client.clientId === 'ci') {
        return { ...client, secret: '${KC_CI_SECRET}' };
      }

      let updatedClient = { ...client };
      const upperClientId = client.clientId.toLocaleUpperCase();

      if (client.secret && (client.secret.includes('****') || client.clientId === 'api-sso')) {
        const mask = '${KC_REALM_CHANGEME_SECRET}';
        updatedClient.secret = mask.replace('CHANGEME', upperClientId);
      }

      if (client.redirectUris && client.clientId === 'api-sso') {
        const mask = '${KC_REALM_CHANGEME_REDIRECT_URIS}';
        updatedClient.redirectUris = [mask.replace('CHANGEME', upperClientId)];
      }

      return updatedClient;
    });
    const clients = [...modifiedClients];
    
    // Filter out default Keycloak roles, keeping only custom roles
    const defaultRoleNames = ['offline_access', 'uma_authorization', 'default-roles-api-realm'];
    const filteredRealmRoles = oldRoles.realm.filter(
      (role) => !defaultRoleNames.includes(role.name)
    );
    
    const roles = { realm: filteredRealmRoles };

    const users = oldUsers.map((user) => {
      if (user.email === 'test@domain.com') {
        return {
          ...user,
          credentials: [
            {
              type: 'password',
              value: '${KC_TEST_USER_PASSWORD}',
              temporary: false,
            },
          ],
        };
      }
      return user;
    });

    const finalRealm = { ...compactedRealm, roles, clients, users };

    await fs.writeFile(outputFilePath, JSON.stringify(finalRealm, null, 2));
  } catch (error) {
    console.log(error);
  }
}

const generate = async () => {
  program
    // .option('-l, --limit <number>', 'operations depthLimit', myParseInt, 2)
    .option('-s, --clientSecret <string>', 'ci clientID secret')
    .requiredOption('-r, --realmName <string>', 'realm name')
    .requiredOption('-f, --outputFilePath <string>', 'the output file path', './realm.json')
    .action(async (options) => {
      const { clientSecret = '', realmName = '', outputFilePath = '' } = options;
      const filePath = path.resolve(outputFilePath);
      try {
        await main(clientSecret, realmName, filePath);
      } catch (err) {
        console.warn({ err, message: err.message });
      }
    });
};

const bootstrap = async () => {
  try {
    console.log('exporting ...');
    await generate();
    await program.parseAsync();
    console.log('realm exported');
  } catch (error) {
    console.log({ error, message: error.message });
  }
};

bootstrap();