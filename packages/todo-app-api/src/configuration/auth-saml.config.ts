import { registerAs } from '@nestjs/config';

export const authSamlConfig = registerAs('auth_saml', () => ({
  entryPoint: process.env.SAML_ENTRYPOINT,
  issuer: process.env.SAML_ISSUER,
  cert: process.env.SAML_CERT,
  path: process.env.SAML_PATH,
  jwtSecret: process.env.JWT_SECRET,
  jwtAccessExpiresIn: parseInt(process.env.JWT_EXPIRES_IN || '3600', 10),
  jwtAccessCookieName: process.env.JWT_COOKIE_NAME,
  jwtRefreshCookieName: process.env.JWT_REFRESH_COOKIE,
  jwtRefreshExpiresIn: parseInt(process.env.JWT_REFRESH_EXPIRES_IN || '86400', 10),
  frontendUrl: process.env.FRONTEND_URL,
}));
