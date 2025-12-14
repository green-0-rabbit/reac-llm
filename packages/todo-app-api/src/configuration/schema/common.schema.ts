import * as Joi from 'joi';

export type NODE_ENV_TYPE = 'dev' | 'prod' | 'staging' | 'test';
export const commonSchema = {
    NODE_ENV: Joi.string().valid('dev', 'prod', 'staging', 'test').default('dev'),
};