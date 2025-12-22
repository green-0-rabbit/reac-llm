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
  UploadedFile,
  UseFilters,
  UseInterceptors,
  Logger,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBody,
  ApiConsumes,
  ApiForbiddenResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { OkResponse } from '../common/responses';
import { HttpExceptionFilter, ORMExceptionFilter } from '../common';
import { ValidationRequestException } from '../common/errors';
import { HMValidationPipe } from '../common/pipes';
import { TodoService } from './todo.service';
import { CreateTodoDto, UpdateTodoDto } from './dto';
import { Todo } from './entities/todo.entity';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';

@Controller('todos')
@ApiTags('todos')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@ApiBadRequestResponse({ type: ValidationRequestException })
@UseFilters(HttpExceptionFilter, ORMExceptionFilter)
export class TodoController {
  private readonly logger = new Logger(TodoController.name);

  constructor(private todoService: TodoService) {}

  @Post()
  @ApiOperation({ description: 'Create todo' })
  @ApiOkResponse({ type: Todo })
  @HttpCode(200)
  async createTodo(@Body(new HMValidationPipe()) dto: CreateTodoDto) {
    this.logger.log(`Creating todo with title: ${dto.title}`);
    return this.todoService.create(dto);
  }

  @Post(':id/attachment')
  @ApiOperation({ description: 'Upload attachment for todo' })
  @ApiOkResponse({ type: Todo })
  @UseInterceptors(FileInterceptor('file'))
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: {
          type: 'string',
          format: 'binary',
        },
      },
    },
  })
  async uploadAttachment(
    @Param('id', ParseUUIDPipe) id: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    this.logger.log(`Uploading attachment for todo ${id}`);
    if (file) {
      this.logger.log(`File received: ${file.originalname}, size: ${file.size}`);
    } else {
      this.logger.warn(`No file received for todo ${id}`);
    }
    return this.todoService.addAttachment(id, file);
  }

  @Put(':id')
  @ApiOperation({ description: 'Update todo by id' })
  @ApiOkResponse({ type: Todo })
  async updateTodoById(
    @Param('id', ParseUUIDPipe) id: string,
    @Body(new HMValidationPipe()) dto: UpdateTodoDto,
  ) {
    return this.todoService.updateById(id, dto);
  }

  @Delete(':id')
  @ApiOperation({ description: 'Remove todo by id' })
  @ApiOkResponse({ type: OkResponse })
  async removeTodo(@Param('id', ParseUUIDPipe) id: string) {
    return this.todoService.remove(id);
  }

  @Get()
  @ApiOperation({ description: 'list todos' })
  @ApiOkResponse({ type: [Todo] })
  @ApiForbiddenResponse({ description: 'Forbidden.' })
  async listTodos() {
    return this.todoService.findAll();
  }

  @Get(':id')
  @ApiOperation({ description: 'Find todo by id' })
  @ApiOkResponse({ type: Todo })
  async findTodoById(@Param('id', ParseUUIDPipe) id: string) {
    return this.todoService.findOneById(id);
  }
}
