import * as Joi from 'joi';
import { databaseSchema } from './database.schema';
import { commonSchema } from './common.schema';
import { azureSchema } from './azure.schema';
import { authSchema } from './auth.schema';

export const configurationSchema = Joi.object({
  ...commonSchema,
  ...databaseSchema,
  ...azureSchema,
  ...authSchema,
});

