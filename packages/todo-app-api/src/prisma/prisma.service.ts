import { Injectable, OnModuleDestroy, OnModuleInit, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaClient } from '@prisma/client';
import { DefaultAzureCredential } from '@azure/identity';

@Injectable()
export class PrismaService implements OnModuleInit, OnModuleDestroy {
  private client: PrismaClient;
  private refreshTimeout: NodeJS.Timeout;
  private readonly logger = new Logger(PrismaService.name);

  constructor(private configService: ConfigService) {
    // Return a Proxy to delegate calls to the underlying PrismaClient instance
    return new Proxy(this, {
      get: (target, prop) => {
        // If property exists on PrismaService (this class), return it
        if (prop in target) {
          return target[prop];
        }
        
        // If client is not initialized yet, return undefined to avoid "reading 'then' of undefined" errors
        // during NestJS instantiation checks.
        if (!target.client) {
            return undefined;
        }

        // Otherwise delegate to the current PrismaClient instance
        return target.client[prop];
      },
    });
  }

  async onModuleInit() {
    await this.connect();
  }

  async onModuleDestroy() {
    if (this.refreshTimeout) {
      clearTimeout(this.refreshTimeout);
    }
    await this.disconnect();
  }

  private async connect() {
    this.logger.log('Initializing database connection...');
    const { url, expiresOn } = await this.getConnectionString();
    
    this.client = new PrismaClient({
      datasources: {
        db: { url },
      },
    });

    await this.client.$connect();
    this.logger.log('Database connected successfully.');

    if (expiresOn) {
      this.scheduleNextRotation(expiresOn);
    }
  }

  private scheduleNextRotation(expiresOn: number) {
    if (this.refreshTimeout) {
      clearTimeout(this.refreshTimeout);
    }

    const now = Date.now();
    // Refresh 5 minutes before expiry
    const bufferMs = 5 * 60 * 1000; 
    // Add jitter: random delay between 0 and 2 minutes to prevent thundering herd
    const jitterMs = Math.floor(Math.random() * 2 * 60 * 1000); 
    
    const timeUntilExpiry = expiresOn - now;
    const timeUntilRefresh = Math.max(0, timeUntilExpiry - bufferMs - jitterMs);

    this.logger.log(`Token expires in ${Math.round(timeUntilExpiry / 60000)}m. Scheduling refresh in ${Math.round(timeUntilRefresh / 60000)}m (buffer: 5m, jitter: ${Math.round(jitterMs/1000)}s).`);

    this.refreshTimeout = setTimeout(() => {
      this.rotateConnection().catch(err => {
        this.logger.error('Failed to rotate DB connection token', err);
        // Retry rotation in 1 minute if it failed
        this.refreshTimeout = setTimeout(() => this.rotateConnection().catch(e => this.logger.error('Retry failed', e)), 60 * 1000);
      });
    }, timeUntilRefresh);
  }

  private async rotateConnection() {
    this.logger.log('Rotating database connection with new token...');
    
    try {
      const { url, expiresOn } = await this.getConnectionString();
      
      const newClient = new PrismaClient({
        datasources: {
          db: { url },
        },
      });

      // Warm up the new connection
      await newClient.$connect();

      // Hot swap
      const oldClient = this.client;
      this.client = newClient;

      this.logger.log('Database connection rotated successfully.');

      if (expiresOn) {
        this.scheduleNextRotation(expiresOn);
      }

      // Gracefully disconnect old client
      await oldClient.$disconnect();
    } catch (error) {
        this.logger.error("Error during connection rotation", error);
        // Retry in 30s
        this.refreshTimeout = setTimeout(() => this.rotateConnection(), 30 * 1000); 
    }
  }

  private async disconnect() {
    if (this.client) {
      await this.client.$disconnect();
    }
  }

  private shouldUseManagedIdentity(): boolean {
    const user = this.configService.get<string>('DATABASE_USERNAME');
    const password = this.configService.get<string>('DATABASE_PASSWORD');
    // If username exists but no password, we assume Managed Identity
    return !!user && !password;
  }

  private async getConnectionString(): Promise<{ url: string; expiresOn?: number }> {
    const host = this.configService.get<string>('DATABASE_HOST');
    const port = this.configService.get<number>('DATABASE_PORT') || 5432;
    const dbName = this.configService.get<string>('DATABASE_SCHEMA');
    const user = this.configService.get<string>('DATABASE_USERNAME');
    let password = this.configService.get<string>('DATABASE_PASSWORD');
    const ssl = this.configService.get<boolean>('DATABASE_SSL') !== false;
    let expiresOn: number | undefined;

    if (!host || !user || !dbName) {
      if (this.configService.get('NODE_ENV') !== 'test') {
        this.logger.warn('Missing database configuration (HOST, USER, or SCHEMA).');
      }
    }

    if (this.shouldUseManagedIdentity()) {
        try {
            this.logger.debug(`Fetching new Managed Identity token for user: ${user}`);
            const credential = new DefaultAzureCredential();
            const tokenResponse = await credential.getToken("https://ossrdbms-aad.database.windows.net/.default");
            password = tokenResponse.token;
            expiresOn = tokenResponse.expiresOnTimestamp;
            this.logger.debug(`Token acquired. Expires on: ${new Date(expiresOn).toISOString()}`);
        } catch (error) {
            this.logger.error(`Failed to acquire token: ${error.message}`);
            throw error;
        }
    }

    const encodedPassword = encodeURIComponent(password || '');
    return {
        url: `postgresql://${user}:${encodedPassword}@${host}:${port}/${dbName}${ssl ? '?sslmode=require' : ''}`,
        expiresOn
    };
  }
}

// Declaration merging to make PrismaService type-compatible with PrismaClient for consumers
export interface PrismaService extends PrismaClient {}
