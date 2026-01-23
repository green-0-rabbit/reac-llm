import * as Joi from 'joi';

export const authSamlSchema = {
  SAML_ENTRYPOINT: Joi.string().required(),
  SAML_ISSUER: Joi.string().required(),
  SAML_CERT: Joi.string().required(),
  SAML_PATH: Joi.string().default('/auth/saml/callback'),
  JWT_EXPIRES_IN: Joi.number().default(3600),
  JWT_SECRET: Joi.string().required(),
  JWT_COOKIE_NAME: Joi.string().default('Authentication'),
  JWT_REFRESH_COOKIE: Joi.string().default('rt'),
  JWT_REFRESH_EXPIRES_IN: Joi.number().default(86400),
  
  FRONTEND_URL: Joi.string().required(),
};
