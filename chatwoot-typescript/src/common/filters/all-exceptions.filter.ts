import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  LoggerService,
} from '@nestjs/common';
import { Request, Response } from 'express';
import { QueryFailedError } from 'typeorm';

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  constructor(private readonly logger: LoggerService) {}

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message = 'Internal server error';
    let errorDetails: Record<string, unknown> = {};

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const exceptionResponse = exception.getResponse();
      message =
        typeof exceptionResponse === 'string'
          ? exceptionResponse
          : (exceptionResponse as Record<string, unknown>).message?.toString() ||
            'An error occurred';
      if (typeof exceptionResponse === 'object') {
        errorDetails = exceptionResponse as Record<string, unknown>;
      }
    } else if (exception instanceof QueryFailedError) {
      status = HttpStatus.BAD_REQUEST;
      message = 'Database query failed';
      errorDetails = {
        query: exception.query,
        parameters: exception.parameters,
      };
    } else if (exception instanceof Error) {
      message = exception.message;
      errorDetails = {
        name: exception.name,
        stack: exception.stack,
      };
    }

    const errorResponse = {
      statusCode: status,
      timestamp: new Date().toISOString(),
      path: request.url,
      method: request.method,
      message,
      ...errorDetails,
    };

    // Log error with full details
    this.logger.error(
      `Unhandled Exception: ${message}`,
      JSON.stringify({
        ...errorResponse,
        stack: exception instanceof Error ? exception.stack : undefined,
      }),
    );

    // In production, don't expose stack traces
    const isProduction = process.env.NODE_ENV === 'production';
    if (isProduction && 'stack' in errorResponse) {
      delete (errorResponse as Record<string, unknown>).stack;
    }

    response.status(status).json(errorResponse);
  }
}
