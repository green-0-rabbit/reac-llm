import { defineConfig } from "@mikro-orm/postgresql";
import { TsMorphMetadataProvider } from "@mikro-orm/reflection";
import { SqlHighlighter } from "@mikro-orm/sql-highlighter";
import { defineConfig as sqliteDefineConfig, Options, LoadStrategy } from "@mikro-orm/sqlite";
import { ConfigService } from "@nestjs/config";

export interface IDatabaseConfigDevParams {
  dbName?: string;
  maxPoolSize?: number;
  idleTimeoutMillis?: number;
}

export interface IDatabaseConfigParams extends IDatabaseConfigDevParams {
  host?: string;
  port?: number;
  user?: string;
  password?: string;
  ssl?: boolean;
}

export function mikroOrmConfig(params: IDatabaseConfigParams) {
  const {
    host,
    port,
    user,
    password,
    dbName,
    ssl,
    maxPoolSize,
    idleTimeoutMillis
  } = params;

  return defineConfig({
    forceUtcTimezone: true,
    host,
    port,
    user,
    password,
    dbName,
    driverOptions: {
      connection: {
        ssl
      }
    },
    pool: {
      min: 5,
      max: maxPoolSize,
      idleTimeoutMillis: idleTimeoutMillis
    }
  });
}

export function mikroOrmConfigDev(params: IDatabaseConfigDevParams) {
  const { dbName, maxPoolSize, idleTimeoutMillis } = params;
  

  return sqliteDefineConfig({
    strict: true,
    forceUtcTimezone: true,
    dbName,
    pool: {
      min: 5,
      max: maxPoolSize,
      idleTimeoutMillis: idleTimeoutMillis
    },
    metadataProvider: TsMorphMetadataProvider,
  });
}


const configService = new ConfigService();


// only useful for mikro-orm CLI ( migrations, seeder ...)
const MikroOrmCLIConfig: Options = sqliteDefineConfig({
  // for simplicity, we use the SQLite database, as it's available pretty much everywhere
  dbName: configService.get<string>("DATABASE_SCHEMA"),
  // folder based discovery setup, using common filename suffix
  entities: ["dist/**/*.entity.js"],
  entitiesTs: ["src/**/*.entity.ts"],
  // enable debug mode to log SQL queries and discovery information
  debug: configService.get<boolean>("DATABASE_DEBUG_LOGGING"),
  // for vitest to get around `TypeError: Unknown file extension ".ts"` (ERR_UNKNOWN_FILE_EXTENSION)
  // dynamicImportProvider: (id) => import(id),
  // for highlighting the SQL queries
  highlighter: new SqlHighlighter(),
  loadStrategy: LoadStrategy.JOINED,
  metadataProvider: TsMorphMetadataProvider,
  migrations: {
    path: "dist/migrations",
    pathTs: "src/migrations",
    snapshot: false // change to "true" after dev iteration
  },
  // seeder
  seeder: {
    path: "dist/seeder",
    pathTs: "src/seeder",
    defaultSeeder: "DatabaseSeeder",
    glob: "*.{js,ts}",
    emit: "ts",
    fileName: (className: string) => className
  }
});

export default MikroOrmCLIConfig