import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Post,
  Put,
  UseFilters
} from "@nestjs/common";
import {
  ApiBadRequestResponse,
  ApiForbiddenResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags
} from "@nestjs/swagger";
import { OkResponse } from "../common/responses";
import { HttpExceptionFilter, ORMExceptionFilter } from "../common";
import { ValidationRequestException } from "../common/errors";
import { HMValidationPipe } from "../common/pipes";
import { TodoService } from "./todo.service";
import { CreateTodoDto, UpdateTodoDto } from "./dto";
import { Todo } from "./entities/todo.entity";

@Controller("todos")
@ApiTags("todos")
@ApiBadRequestResponse({ type: ValidationRequestException })
@UseFilters(HttpExceptionFilter, ORMExceptionFilter)
export class TodoController {
  constructor(private todoService: TodoService) {}

  @Post()
  @ApiOperation({ description: "Create todo" })
  @ApiOkResponse({ type: Todo })
  @HttpCode(200)
  async createTodo(@Body(new HMValidationPipe()) dto: CreateTodoDto) {
    return this.todoService.create(dto);
  }
  
  @Put(":id")
  @ApiOperation({ description: "Update todo by id" })
  @ApiOkResponse({type: Todo})
  async updateTodoById(
    @Param("id", ParseUUIDPipe) id: string,
    @Body(new HMValidationPipe()) dto: UpdateTodoDto
  ) {
    return  this.todoService.updateById(id, dto);
  }

  @Delete(":id")
  @ApiOperation({ description: "Remove todo by id" })
  @ApiOkResponse({ type: OkResponse })
  async removeTodo(@Param("id", ParseUUIDPipe) id: string) {
    return this.todoService.remove(id);
  }


  @Get()
  @ApiOperation({ description: "list todos" })
  @ApiOkResponse({ type: [Todo] })
  @ApiForbiddenResponse({ description: "Forbidden." })
  async listTodos() {
    return this.todoService.findAll();
  }

  @Get(":id")
  @ApiOperation({ description: "Find todo by id" })
  @ApiOkResponse({ type: Todo })
  async findTodoById(@Param("id", ParseUUIDPipe) id: string) {
    return this.todoService.findOneById(id);
  }

}
