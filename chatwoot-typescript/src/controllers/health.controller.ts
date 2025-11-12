import { Controller, Get } from '@nestjs/common';
import {
  HealthCheckService,
  HealthCheck,
  TypeOrmHealthIndicator,
  MemoryHealthIndicator,
  DiskHealthIndicator,
} from '@nestjs/terminus';
import Redis from 'ioredis';
import { RedisConfigService } from '@config/redis.config';

@Controller('health')
export class HealthController {
  private redis: Redis;

  constructor(
    private health: HealthCheckService,
    private db: TypeOrmHealthIndicator,
    private memory: MemoryHealthIndicator,
    private disk: DiskHealthIndicator,
    private redisConfigService: RedisConfigService,
  ) {
    // Create Redis client for health checks
    this.redis = new Redis(this.redisConfigService.getRedisConfig());
  }

  @Get()
  @HealthCheck()
  check() {
    return this.health.check([
      // Database health check
      () => this.db.pingCheck('database'),

      // Redis health check
      async () => {
        const isHealthy = this.redis.status === 'ready';
        return {
          redis: {
            status: isHealthy ? 'up' : 'down',
          },
        };
      },

      // Memory health check (heap should not exceed 300MB)
      () => this.memory.checkHeap('memory_heap', 300 * 1024 * 1024),

      // Memory health check (RSS should not exceed 500MB)
      () => this.memory.checkRSS('memory_rss', 500 * 1024 * 1024),

      // Disk health check (should have at least 50% free space)
      () =>
        this.disk.checkStorage('disk', {
          path: '/',
          thresholdPercent: 0.5,
        }),
    ]);
  }

  @Get('live')
  @HealthCheck()
  live() {
    // Liveness probe - just check if the app is running
    return this.health.check([]);
  }

  @Get('ready')
  @HealthCheck()
  ready() {
    // Readiness probe - check if app can serve traffic
    return this.health.check([
      () => this.db.pingCheck('database'),
      async () => {
        const isHealthy = this.redis.status === 'ready';
        return {
          redis: {
            status: isHealthy ? 'up' : 'down',
          },
        };
      },
    ]);
  }
}
