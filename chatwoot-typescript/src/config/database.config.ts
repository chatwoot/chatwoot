import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { TypeOrmModuleOptions, TypeOrmOptionsFactory } from '@nestjs/typeorm';
import { RailsNamingStrategy } from './rails-naming.strategy';

@Injectable()
export class DatabaseConfigService implements TypeOrmOptionsFactory {
  constructor(private configService: ConfigService) {}

  createTypeOrmOptions(): TypeOrmModuleOptions {
    return {
      type: 'postgres',
      host: this.configService.get<string>('database.host'),
      port: this.configService.get<number>('database.port'),
      username: this.configService.get<string>('database.username'),
      password: this.configService.get<string>('database.password'),
      database: this.configService.get<string>('database.name'),
      ssl: this.configService.get<boolean>('database.ssl')
        ? { rejectUnauthorized: false }
        : false,
      entities: [__dirname + '/../**/*.entity{.ts,.js}'],
      migrations: [__dirname + '/../database/migrations/*{.ts,.js}'],
      synchronize: false, // Never use synchronize in production
      logging: this.configService.get<string>('app.nodeEnv') === 'development',
      poolSize: this.configService.get<number>('database.poolSize'),
      namingStrategy: new RailsNamingStrategy(), // Use Rails naming conventions
      extra: {
        max: this.configService.get<number>('database.poolSize'),
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: 2000,
      },
    };
  }
}
