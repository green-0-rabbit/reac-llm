import { Module } from '@nestjs/common';
import { ConfigModule as NestConfigModule } from '@nestjs/config';
import { configurationSchema } from './schema/configuration.schema';
import { authSamlConfig } from './auth-saml.config';

@Module({
    imports: [
        NestConfigModule.forRoot({
            ignoreEnvFile: true,
            validationSchema: configurationSchema,
            isGlobal: true,
            cache: true,
            load: [authSamlConfig],
        }),
    ],
    providers: [],
    exports: [],
})
export class ConfigurationModule { }