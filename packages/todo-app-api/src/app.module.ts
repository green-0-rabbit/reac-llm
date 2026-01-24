import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { AIModule } from './ai/ai.module';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { ConfigurationModule } from './configuration/configuration.module';
import { DatabaseModule } from './database/database.module';
import { StorageModule } from './storage/storage.module';
import { TodoModule } from './todos/todo.module';
import { PrismaModule } from './prisma/prisma.module';

@Module({
  imports: [
    PrismaModule,
    ConfigurationModule,
    DatabaseModule.registerAsync(),
    TodoModule,
    StorageModule,
    AIModule,
    // Conditionally load auth module based on requirements, or keep both if clear separation
    // AuthModule,
    // AuthSamlModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer
      .apply((req, res, next) => {
        console.log(`[GlobalMiddleware] Incoming Request: ${req.method} ${req.originalUrl}`);
        next();
      })
      .forRoutes('*');
  }
}
