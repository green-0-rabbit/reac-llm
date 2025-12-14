import { Injectable } from "@nestjs/common";
import { EntityManager } from "@mikro-orm/core";
import { OkResponse } from "../common/responses";
import { TodoRepository } from "./todo.repository";
import { CreateTodoDto, UpdateTodoDto } from "./dto";

@Injectable()
export class TodoService {
  constructor(
    private readonly todoRepository: TodoRepository,
    private readonly em: EntityManager
  ) {}

  create = async (dto: CreateTodoDto) => {
    const todo = this.todoRepository.create({
      ...dto
    });
    await this.em.flush();
    return todo;
  };

  findAll = async () => {
    return this.todoRepository.findAll();
  };

  findOneById = async (id: string) => {
    return this.todoRepository.findOneOrFail({ id });
  };

  updateById = async (id: string, dto: UpdateTodoDto) => {
    const todo = await this.todoRepository.findOneOrFail({ id });
    this.todoRepository.assign(todo, dto);
    await this.em.flush();
    return todo;
  };

  remove = async (id: string) => {
    await this.todoRepository.nativeDelete({ id });
    return new OkResponse();
  };
}
