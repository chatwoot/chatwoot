import { Module, Global } from '@nestjs/common';
import { CacheModule } from '@nestjs/cache-manager';
import { BullModule } from '@nestjs/bullmq';
import { ConfigModule } from '@nestjs/config';
import { redisStore } from 'cache-manager-redis-store';
import { RedisConfigService } from '@config/redis.config';

@Global()
@Module({
  imports: [
    // Cache Manager with Redis
    CacheModule.registerAsync({
      isGlobal: true,
      imports: [ConfigModule],
      inject: [RedisConfigService],
      useFactory: async (redisConfigService: RedisConfigService) => {
        const redisConfig = redisConfigService.getRedisConfig();
        return {
          store: redisStore,
          ...redisConfig,
          ttl: 60 * 60, // 1 hour default TTL
        };
      },
    }),

    // BullMQ for background jobs
    BullModule.forRootAsync({
      imports: [ConfigModule],
      inject: [RedisConfigService],
      useFactory: (redisConfigService: RedisConfigService) => ({
        connection: redisConfigService.getRedisConfig(),
        defaultJobOptions: {
          attempts: 3,
          backoff: {
            type: 'exponential',
            delay: 1000,
          },
          removeOnComplete: {
            age: 3600, // Keep completed jobs for 1 hour
            count: 1000, // Keep max 1000 completed jobs
          },
          removeOnFail: {
            age: 86400, // Keep failed jobs for 24 hours
            count: 5000, // Keep max 5000 failed jobs
          },
        },
      }),
    }),
  ],
  providers: [RedisConfigService],
  exports: [RedisConfigService, CacheModule],
})
export class RedisModule {}
