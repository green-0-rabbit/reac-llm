import * as Joi from 'joi';

export const azureSchema = {
  AZURE_STORAGE_SERVICE_URI: Joi.string().uri().required(),
  AZURE_STORAGE_CONTAINER_NAME: Joi.string().required(),
};
