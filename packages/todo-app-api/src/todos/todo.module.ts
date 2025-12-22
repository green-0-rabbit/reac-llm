import { MikroOrmModule } from '@mikro-orm/nestjs';
import { Module } from '@nestjs/common';
import { TodoController } from './todo.controller';
import { TodoService } from './todo.service';
import { Todo } from './entities/todo.entity';
import { StorageModule } from '../storage/storage.module';

@Module({
  imports: [MikroOrmModule.forFeature([Todo]), StorageModule],
  controllers: [TodoController],
  providers: [TodoService],
})
export class TodoModule {}
