import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { RedisOptions } from 'ioredis';

@Injectable()
export class RedisConfigService {
  private readonly logger = new Logger(RedisConfigService.name);

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
      lazyConnect: true, // Don't connect immediately, prevents startup crash
      retryStrategy: (times: number) => {
        if (times > 10) {
          this.logger.error('Redis connection failed after 10 retries');
          return null; // Stop retrying
        }
        const delay = Math.min(times * 1000, 5000); // Max 5 seconds
        this.logger.warn(`Redis reconnecting in ${delay}ms (attempt ${times})`);
        return delay;
      },
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
