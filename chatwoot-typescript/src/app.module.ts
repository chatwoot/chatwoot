import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { WinstonModule } from 'nest-winston';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import configurations from './config/configuration';
import { validate } from './config/env.validation';
import { LoggerConfigService } from './config/logger.config';
import { RedisConfigService } from './config/redis.config';
import { DatabaseModule } from './modules/database.module';
import { RedisModule } from './modules/redis.module';
import { HealthModule } from './modules/health.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: configurations,
      validate,
      envFilePath: ['.env.local', '.env'],
      cache: true,
    }),
    WinstonModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => {
        const loggerConfigService = new LoggerConfigService(configService);
        return loggerConfigService.createWinstonModuleOptions();
      },
    }),
    DatabaseModule,
    RedisModule,
    HealthModule,
  ],
  controllers: [AppController],
  providers: [AppService, LoggerConfigService, RedisConfigService],
})
export class AppModule {}
