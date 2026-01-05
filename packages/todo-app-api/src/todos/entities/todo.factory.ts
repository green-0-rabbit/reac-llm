import { Factory } from "@mikro-orm/seeder";
import { Todo } from "./todo.entity";
import { faker } from "@faker-js/faker";

export class TodoFactory extends Factory<Todo> {
  model = Todo;

  definition(): Partial<Todo> {
    return {
      title: faker.lorem.words({ min: 2, max: 5 }),
      isCompleted: faker.datatype.boolean()
    };
  }
}
