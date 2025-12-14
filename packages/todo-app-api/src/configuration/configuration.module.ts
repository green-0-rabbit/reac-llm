import { Module } from '@nestjs/common';
import { ConfigModule as NestConfigModule } from '@nestjs/config';
import { configurationSchema } from './schema/configuration.schema';

@Module({
    imports: [
        NestConfigModule.forRoot({
            ignoreEnvFile: true,
            validationSchema: configurationSchema,
            isGlobal: true,
            cache: true,
        }),
    ],
    providers: [],
    exports: [],
})
export class ConfigurationModule { }