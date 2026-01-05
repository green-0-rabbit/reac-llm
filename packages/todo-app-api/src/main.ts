import { NestFactory } from "@nestjs/core";
import cookieParser from "cookie-parser";
import helmet from "helmet";
import { ConfigService } from "@nestjs/config";
import express from "express";
import { AppModule } from "./app.module";
import { DocumentBuilder, SwaggerModule } from "@nestjs/swagger";
import { MikroORM } from "@mikro-orm/core";
import { DatabaseSeeder } from "./seeder/database.seeder";

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  // https://mikro-orm.io/docs/usage-with-nestjs#app-shutdown-and-cleanup
  app.enableShutdownHooks();
  const configService = app.get(ConfigService);

  const nodeEnv = configService.get("NODE_ENV");
  if (nodeEnv === "dev" || nodeEnv === "prod") {
    const orm = app.get(MikroORM);
    await orm.schema.refreshDatabase();
    await orm.seeder.seed(DatabaseSeeder);
  }

  /**
   * @see https://mikro-orm.io/docs/usage-with-nestjs#request-scoping-when-using-graphql
   * or use   body-parser @see https://www.npmjs.com/package/body-parser#bodyparserrawoptions
   */
  app.use(express.json());
  // https://stackoverflow.com/a/66769957
  // https://www.apollographql.com/docs/react/networking/authentication/#cookie
  app.enableCors({ origin: "http://localhost:3000", credentials: true });
  app.use(cookieParser()); // Parse the `/token` refresh cookie
  /**
   * @see https://docs.nestjs.com/security/helmet#use-with-fastify
   * @see https://github.com/graphql/graphql-playground/issues/1283#issuecomment-723686116
   */
  app.use(
    helmet({
      contentSecurityPolicy:
        configService.get("NODE_ENV") === "dev" ? false : undefined,
      crossOriginEmbedderPolicy:
        configService.get("NODE_ENV") === "dev" ? false : undefined
    })
  ); // Set sensible headers for improved security

  const config = new DocumentBuilder()
    .setTitle("Devices management api")
    .setDescription("API for managing IoT devices, including creation, updates, and querying of device details.")
    .setVersion("1.0")
    .build();
  const document = SwaggerModule.createDocument(app, config, {
    operationIdFactory: (controllerKey: string, methodKey: string) => methodKey
  });
  SwaggerModule.setup("api", app, document, {jsonDocumentUrl: "/api/openapi.json"});

  await app.listen(configService.get("PORT") ?? 3001, '0.0.0.0')
}
bootstrap();