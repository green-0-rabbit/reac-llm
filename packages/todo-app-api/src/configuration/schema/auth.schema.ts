import * as Joi from 'joi';

export const authSchema = {
  AUTH_ISSUER_URL: Joi.string().required(),
  AUTH_JWKS_URI: Joi.string().optional(),
};
