import { Module, Logger, Global } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { DefaultAzureCredential } from '@azure/identity';
import { PrismaService } from './prisma.service';
import { PrismaTestController } from './prisma-test.controller';

@Global()
@Module({
  imports: [ConfigModule],
  controllers: [PrismaTestController],
  providers: [
    {
      provide: PrismaService,
      useFactory: async (configService: ConfigService) => {
        const logger = new Logger('PrismaModule');
        const host = configService.get<string>('DATABASE_HOST');
        const port = configService.get<number>('DATABASE_PORT');
        const dbName = configService.get<string>('DATABASE_SCHEMA');
        const user = configService.get<string>('DATABASE_USERNAME');
        let password = configService.get<string>('DATABASE_PASSWORD');
        const nodeEnv = configService.get<string>('NODE_ENV');
        const ssl = configService.get<boolean>('DATABASE_SSL') !== false;

        // Determine if we should use Managed Identity
        // Logic: If explicitly enabled or if password is missing in non-local env
        const useManagedIdentity = !password && user; // Simplified check

        if (useManagedIdentity) {
          logger.log(`Authenticating with Managed Identity for user: ${user}`);
          try {
            const credential = new DefaultAzureCredential();
            const tokenResponse = await credential.getToken("https://ossrdbms-aad.database.windows.net/.default");
            password = tokenResponse.token;
            logger.log('Successfully retrieved Azure AD Token');
          } catch (error) {
            logger.error(`Failed to retrieve Azure AD Token: ${error.message}`, error.stack);
            throw error;
          }
        }

        if (!host || !user || !dbName) {
            // This might happen during build or test if env vars are missing
             logger.warn('Missing database configuration. PrismaService will fail to connect.');
        }

        const connectionString = `postgresql://${user}:${encodeURIComponent(password || '')}@${host}:${port}/${dbName}${ssl ? '?sslmode=require' : ''}`;
        
        return new PrismaService(connectionString);
      },
      inject: [ConfigService],
    },
  ],
  exports: [PrismaService],
})
export class PrismaModule {}
