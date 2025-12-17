import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { ConfigurationModule } from './configuration/configuration.module';
import { DatabaseModule } from './database/database.module';
import { TodoModule } from './todos/todo.module';
import { StorageModule } from './storage/storage.module';

@Module({
  imports: [
    ConfigurationModule,
    DatabaseModule.registerAsync(),
    TodoModule,
    StorageModule,
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
