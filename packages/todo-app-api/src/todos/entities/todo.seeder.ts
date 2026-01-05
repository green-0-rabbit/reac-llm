import { Dictionary, EntityManager } from "@mikro-orm/core";
import { Seeder } from "@mikro-orm/seeder";
import { TodoFactory } from "./todo.factory";

export class TodoSeeder extends Seeder {
  async run(em: EntityManager, context: Dictionary): Promise<void> {
    const todoFactory = new TodoFactory(em);
    todoFactory.make(10);
  }
}
