import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TerminusModule } from '@nestjs/terminus';
import { HttpModule } from '@nestjs/axios';
import { HealthController } from '@controllers/health.controller';
import { RedisConfigService } from '@config/redis.config';

@Module({
  imports: [ConfigModule, TerminusModule, HttpModule],
  controllers: [HealthController],
  providers: [RedisConfigService],
})
export class HealthModule {}
