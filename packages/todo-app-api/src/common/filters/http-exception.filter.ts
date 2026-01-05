import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  Logger
} from "@nestjs/common";
import { Response } from "express";
import { ValidationRequestException } from "../errors";

@Catch(HttpException)
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);

  catch(exception: HttpException, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const statusCode = exception.getStatus();
    const { message, name } = exception;

    this.logger.error(`Http Exception: ${message}`, exception.stack);

    if (exception instanceof ValidationRequestException) {
      const { details } = exception;

      return response.status(statusCode).json({
        statusCode,
        details,
        message: "Dto validation error"
      });
    }

    response.status(statusCode || 400).json({
      statusCode,
      message,
      name
    });
  }
}
