import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { RedisOptions } from 'ioredis';

@Injectable()
export class RedisConfigService {
  constructor(private configService: ConfigService) {}

  getRedisConfig(): RedisOptions {
    return {
      host: this.configService.get<string>('redis.host'),
      port: this.configService.get<number>('redis.port'),
      password: this.configService.get<string>('redis.password') || undefined,
      db: this.configService.get<number>('redis.db'),
      ...(this.configService.get<boolean>('redis.tls') && {
        tls: {},
      }),
      maxRetriesPerRequest: 3,
      enableReadyCheck: true,
      enableOfflineQueue: true,
    };
  }

  getConnectionString(): string {
    const password = this.configService.get<string>('redis.password');
    const host = this.configService.get<string>('redis.host');
    const port = this.configService.get<number>('redis.port');
    const db = this.configService.get<number>('redis.db');

    if (password) {
      return `redis://:${password}@${host}:${port}/${db}`;
    }
    return `redis://${host}:${port}/${db}`;
  }
}
