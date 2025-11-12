import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { WinstonModuleOptions, utilities as nestWinstonModuleUtilities } from 'nest-winston';
import * as winston from 'winston';
import * as DailyRotateFile from 'winston-daily-rotate-file';
import { LogLevel } from './env.validation';

@Injectable()
export class LoggerConfigService {
  constructor(private configService: ConfigService) {}

  createWinstonModuleOptions(): WinstonModuleOptions {
    const logLevel = this.configService.get<LogLevel>('logging.level') || LogLevel.Info;
    const logFileEnabled = this.configService.get<boolean>('logging.fileEnabled');
    const logFilePath = this.configService.get<string>('logging.filePath') || './logs';
    const nodeEnv = this.configService.get<string>('app.nodeEnv');

    const transports: winston.transport[] = [
      // Console transport with colorization for development
      new winston.transports.Console({
        format: winston.format.combine(
          winston.format.timestamp(),
          winston.format.ms(),
          nestWinstonModuleUtilities.format.nestLike('Chatwoot', {
            colors: true,
            prettyPrint: true,
          }),
        ),
      }),
    ];

    // Add file transports if enabled
    if (logFileEnabled) {
      // Error logs
      transports.push(
        new DailyRotateFile({
          filename: `${logFilePath}/error-%DATE%.log`,
          datePattern: 'YYYY-MM-DD',
          level: 'error',
          maxFiles: '30d',
          maxSize: '20m',
          format: winston.format.combine(
            winston.format.timestamp(),
            winston.format.errors({ stack: true }),
            winston.format.json(),
          ),
        }),
      );

      // Combined logs
      transports.push(
        new DailyRotateFile({
          filename: `${logFilePath}/combined-%DATE%.log`,
          datePattern: 'YYYY-MM-DD',
          maxFiles: '14d',
          maxSize: '20m',
          format: winston.format.combine(
            winston.format.timestamp(),
            winston.format.errors({ stack: true }),
            winston.format.json(),
          ),
        }),
      );

      // Application logs (info and above)
      transports.push(
        new DailyRotateFile({
          filename: `${logFilePath}/app-%DATE%.log`,
          datePattern: 'YYYY-MM-DD',
          level: 'info',
          maxFiles: '14d',
          maxSize: '20m',
          format: winston.format.combine(winston.format.timestamp(), winston.format.json()),
        }),
      );
    }

    return {
      level: logLevel,
      transports,
      exceptionHandlers:
        logFileEnabled && nodeEnv === 'production'
          ? [
              new DailyRotateFile({
                filename: `${logFilePath}/exceptions-%DATE%.log`,
                datePattern: 'YYYY-MM-DD',
                maxFiles: '30d',
                maxSize: '20m',
              }),
            ]
          : undefined,
      rejectionHandlers:
        logFileEnabled && nodeEnv === 'production'
          ? [
              new DailyRotateFile({
                filename: `${logFilePath}/rejections-%DATE%.log`,
                datePattern: 'YYYY-MM-DD',
                maxFiles: '30d',
                maxSize: '20m',
              }),
            ]
          : undefined,
    };
  }
}
