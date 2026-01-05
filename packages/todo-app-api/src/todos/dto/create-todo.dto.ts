import { OmitType } from "@nestjs/swagger";
import { Todo } from "../entities/todo.entity";

export class CreateTodoDto extends OmitType(Todo, ["id", "createdAt", "updatedAt"] as const) {}
