import { EntityRepository } from "@mikro-orm/postgresql";
import { Todo } from "./entities/todo.entity";

export class TodoRepository extends EntityRepository<Todo> {}
