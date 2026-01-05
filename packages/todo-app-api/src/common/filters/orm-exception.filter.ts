import { NotFoundError } from "@mikro-orm/core";
import {
  ArgumentsHost,
  Catch,
  ExceptionFilter
} from "@nestjs/common";
import { Response } from "express";

@Catch(NotFoundError)
export class ORMExceptionFilter implements ExceptionFilter {
  catch(exception: NotFoundError, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const statusCode = 404;
    const { message, name } = exception;    
    response.status(statusCode).json({
      statusCode,
      message,
      name
    });
  }
}