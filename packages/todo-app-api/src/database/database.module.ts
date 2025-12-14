import { DynamicModule, Module } from "@nestjs/common";
import { ConfigModule, ConfigService } from "@nestjs/config";
import { LoadStrategy } from "@mikro-orm/core";
import { MikroOrmModule } from "@mikro-orm/nestjs";
import { databaseSchema } from "../configuration/schema/database.schema";
import {
  mikroOrmConfig,
  IDatabaseConfigParams,
  mikroOrmConfigDev
} from "./mikro-orm.config";
import { SqlHighlighter } from "@mikro-orm/sql-highlighter";
import {
  commonSchema,
  NODE_ENV_TYPE
} from "../configuration/schema/common.schema";
import { Migrator } from "@mikro-orm/migrations";
import { SeedManager } from "@mikro-orm/seeder";
// import { TsMorphMetadataProvider } from "@mikro-orm/reflection";
import { SqliteDriver } from "@mikro-orm/sqlite";
import { PostgreSqlDriver } from "@mikro-orm/postgresql";

@Module({})
export class DatabaseModule {
  static async registerAsync(): Promise<DynamicModule> {
    const mikroORM = await MikroOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService<typeof databaseSchema>],
      driver: process.env.NODE_ENV === 'prod' ? PostgreSqlDriver : SqliteDriver,
      useFactory: (
        configService: ConfigService<
          typeof databaseSchema & typeof commonSchema
        >
      ) => {
        const highligher = new SqlHighlighter();
        const debug = configService.get<boolean>("DATABASE_DEBUG_LOGGING");
        const nodeEnv = configService.get<string>("NODE_ENV") as NODE_ENV_TYPE;        

        const params: IDatabaseConfigParams = {
          host: configService.get<string>("DATABASE_HOST"),
          port: configService.get<number>("DATABASE_PORT"),
          user: configService.get<string>("DATABASE_USERNAME"),
          password: configService.get<string>("DATABASE_PASSWORD"),
          dbName: configService.get<string>("DATABASE_SCHEMA"),
          ssl: configService.get<boolean>("DATABASE_SSL"),
          maxPoolSize: configService.get<number>("DATABASE_POOLSIZE"),
          idleTimeoutMillis: configService.get<number>("DATABASE_IDLE_TIMEOUT")
        };
        const dbConfig =
          nodeEnv === "dev" || nodeEnv === "test"
            ? mikroOrmConfigDev(params)
            : mikroOrmConfig(params);
        return {
          ...dbConfig,
          // entities: ["dist/**/*.entity.js"],
          // entitiesTs: ["src/**/*.entity.ts"],
          // metadataProvider: TsMorphMetadataProvider,
          highlighter: debug ? highligher : undefined,
          autoLoadEntities: true, 
          strict: true,
          loadStrategy: LoadStrategy.SELECT_IN,
          debug,
          migrations: {
            path: "dist/migrations",
            pathTs: "src/migrations",
            transactional: true,
            allOrNothing: true
          },
          extensions: [Migrator, SeedManager],
          seeder: {
            path: "dist/seeder",
            pathTs: "src/seeder",
            defaultSeeder: "DatabaseSeeder",
            glob: "*.{js,ts}",
            emit: "ts",
            fileName: (className: string) => className
          }
        };
      }
    });

    return {
      module: DatabaseModule,
      imports: [mikroORM],
      providers: [],
      exports: [mikroORM]
    };
  }
}
