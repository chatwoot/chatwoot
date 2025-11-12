import { Controller, Get, Logger } from '@nestjs/common';
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
  private readonly logger = new Logger(HealthController.name);
  private redis: Redis;
  private redisHealthy = false;

  constructor(
    private health: HealthCheckService,
    private db: TypeOrmHealthIndicator,
    private memory: MemoryHealthIndicator,
    private disk: DiskHealthIndicator,
    private redisConfigService: RedisConfigService,
  ) {
    // Create Redis client for health checks with error handling
    this.redis = new Redis(this.redisConfigService.getRedisConfig());

    // Handle Redis connection errors gracefully
    this.redis.on('error', (err: Error) => {
      this.logger.warn(`Redis health check connection error: ${err.message}`);
      this.redisHealthy = false;
    });

    this.redis.on('connect', () => {
      this.logger.log('Redis health check connected');
      this.redisHealthy = true;
    });

    this.redis.on('ready', () => {
      this.logger.log('Redis health check ready');
      this.redisHealthy = true;
    });

    this.redis.on('close', () => {
      this.logger.warn('Redis health check connection closed');
      this.redisHealthy = false;
    });

    // Attempt to connect (non-blocking with lazyConnect)
    this.redis.connect().catch((err: Error) => {
      this.logger.warn(`Redis health check initial connection failed: ${err.message}`);
    });
  }

  @Get()
  @HealthCheck()
  check() {
    return this.health.check([
      // Database health check
      () => this.db.pingCheck('database'),

      // Redis health check with graceful degradation
      async () => {
        try {
          if (!this.redisHealthy) {
            return {
              redis: {
                status: 'down',
                message: 'Not connected',
              },
            };
          }

          await this.redis.ping();
          return {
            redis: {
              status: 'up',
            },
          };
        } catch (error) {
          this.logger.warn(
            `Redis ping failed: ${error instanceof Error ? error.message : 'Unknown error'}`,
          );
          return {
            redis: {
              status: 'down',
              message: error instanceof Error ? error.message : 'Ping failed',
            },
          };
        }
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

      // Redis readiness check
      async () => {
        try {
          if (!this.redisHealthy) {
            return {
              redis: {
                status: 'down',
                message: 'Not connected',
              },
            };
          }

          await this.redis.ping();
          return {
            redis: {
              status: 'up',
            },
          };
        } catch (error) {
          return {
            redis: {
              status: 'down',
              message: error instanceof Error ? error.message : 'Ping failed',
            },
          };
        }
      },
    ]);
  }
}
