import { plainToClass } from 'class-transformer';
import {
  IsString,
  IsNumber,
  IsEnum,
  IsBoolean,
  IsOptional,
  IsUrl,
  validateSync,
  Min,
  Max,
} from 'class-validator';

export enum Environment {
  Development = 'development',
  Production = 'production',
  Test = 'test',
  Staging = 'staging',
}

export enum StorageType {
  Local = 'local',
  S3 = 's3',
  GCS = 'gcs',
}

export enum LogLevel {
  Error = 'error',
  Warn = 'warn',
  Info = 'info',
  Debug = 'debug',
  Verbose = 'verbose',
}

export class EnvironmentVariables {
  // Application
  @IsEnum(Environment)
  NODE_ENV: Environment = Environment.Development;

  @IsNumber()
  @Min(1)
  @Max(65535)
  PORT: number = 3000;

  @IsString()
  APP_NAME: string = 'Chatwoot';

  @IsUrl({ require_tld: false })
  FRONTEND_URL!: string;

  @IsString()
  API_VERSION: string = 'v1';

  // Database
  @IsString()
  DATABASE_HOST!: string;

  @IsNumber()
  @Min(1)
  @Max(65535)
  DATABASE_PORT: number = 5432;

  @IsString()
  DATABASE_NAME!: string;

  @IsString()
  DATABASE_USERNAME!: string;

  @IsString()
  DATABASE_PASSWORD!: string;

  @IsBoolean()
  DATABASE_SSL: boolean = false;

  @IsNumber()
  @Min(1)
  DATABASE_POOL_SIZE: number = 10;

  // Redis
  @IsString()
  REDIS_HOST!: string;

  @IsNumber()
  @Min(1)
  @Max(65535)
  REDIS_PORT: number = 6379;

  @IsOptional()
  @IsString()
  REDIS_PASSWORD?: string;

  @IsNumber()
  @Min(0)
  REDIS_DB: number = 0;

  @IsBoolean()
  REDIS_TLS: boolean = false;

  // Authentication & Security
  @IsString()
  JWT_SECRET!: string;

  @IsString()
  JWT_EXPIRATION: string = '7d';

  @IsString()
  REFRESH_TOKEN_EXPIRATION: string = '30d';

  @IsString()
  SESSION_SECRET!: string;

  // Rate Limiting
  @IsNumber()
  @Min(1000)
  RATE_LIMIT_TTL: number = 60000;

  @IsNumber()
  @Min(1)
  RATE_LIMIT_MAX: number = 100;

  // CORS
  @IsBoolean()
  CORS_ENABLED: boolean = true;

  @IsString()
  CORS_ORIGIN!: string;

  // File Storage
  @IsEnum(StorageType)
  STORAGE_TYPE: StorageType = StorageType.Local;

  @IsOptional()
  @IsString()
  STORAGE_PATH?: string;

  @IsOptional()
  @IsString()
  AWS_ACCESS_KEY_ID?: string;

  @IsOptional()
  @IsString()
  AWS_SECRET_ACCESS_KEY?: string;

  @IsOptional()
  @IsString()
  AWS_REGION?: string;

  @IsOptional()
  @IsString()
  AWS_S3_BUCKET?: string;

  @IsOptional()
  @IsString()
  AWS_S3_ENDPOINT?: string;

  // Email Configuration
  @IsBoolean()
  SMTP_ENABLED: boolean = false;

  @IsOptional()
  @IsString()
  SMTP_HOST?: string;

  @IsOptional()
  @IsNumber()
  SMTP_PORT?: number;

  @IsOptional()
  @IsString()
  SMTP_USERNAME?: string;

  @IsOptional()
  @IsString()
  SMTP_PASSWORD?: string;

  @IsOptional()
  @IsString()
  SMTP_FROM_EMAIL?: string;

  @IsOptional()
  @IsString()
  SMTP_FROM_NAME?: string;

  // Logging
  @IsEnum(LogLevel)
  LOG_LEVEL: LogLevel = LogLevel.Info;

  @IsBoolean()
  LOG_FILE_ENABLED: boolean = true;

  @IsOptional()
  @IsString()
  LOG_FILE_PATH?: string;

  // Background Jobs
  @IsBoolean()
  BULL_BOARD_ENABLED: boolean = true;

  @IsString()
  BULL_BOARD_PATH: string = '/admin/queues';

  // WebSocket
  @IsBoolean()
  WEBSOCKET_ENABLED: boolean = true;

  @IsString()
  WEBSOCKET_PATH: string = '/cable';

  // Integrations - Slack
  @IsOptional()
  @IsString()
  SLACK_CLIENT_ID?: string;

  @IsOptional()
  @IsString()
  SLACK_CLIENT_SECRET?: string;

  @IsOptional()
  @IsString()
  SLACK_VERIFICATION_TOKEN?: string;

  // Integrations - Facebook
  @IsOptional()
  @IsString()
  FACEBOOK_APP_ID?: string;

  @IsOptional()
  @IsString()
  FACEBOOK_APP_SECRET?: string;

  @IsOptional()
  @IsString()
  FACEBOOK_VERIFY_TOKEN?: string;

  // Integrations - WhatsApp
  @IsOptional()
  @IsString()
  WHATSAPP_CLOUD_API_ACCESS_TOKEN?: string;

  @IsOptional()
  @IsString()
  WHATSAPP_CLOUD_API_PHONE_NUMBER_ID?: string;

  @IsOptional()
  @IsString()
  WHATSAPP_CLOUD_API_VERIFY_TOKEN?: string;

  // Integrations - Twilio
  @IsOptional()
  @IsString()
  TWILIO_ACCOUNT_SID?: string;

  @IsOptional()
  @IsString()
  TWILIO_AUTH_TOKEN?: string;

  @IsOptional()
  @IsString()
  TWILIO_PHONE_NUMBER?: string;

  // Analytics & Monitoring
  @IsOptional()
  @IsString()
  SENTRY_DSN?: string;

  @IsOptional()
  @IsString()
  SENTRY_ENVIRONMENT?: string;

  // Feature Flags
  @IsBoolean()
  FEATURE_CUSTOM_ATTRIBUTES: boolean = true;

  @IsBoolean()
  FEATURE_CAMPAIGNS: boolean = true;

  @IsBoolean()
  FEATURE_AUTOMATIONS: boolean = true;

  @IsBoolean()
  FEATURE_MACROS: boolean = true;

  @IsBoolean()
  FEATURE_AGENT_BOTS: boolean = true;

  @IsBoolean()
  FEATURE_SLA: boolean = true;

  // Encryption
  @IsString()
  ENCRYPTION_KEY!: string;

  // OpenAI
  @IsOptional()
  @IsString()
  OPENAI_API_KEY?: string;

  @IsOptional()
  @IsString()
  OPENAI_MODEL?: string;

  // Pusher
  @IsBoolean()
  PUSHER_ENABLED: boolean = false;

  @IsOptional()
  @IsString()
  PUSHER_APP_ID?: string;

  @IsOptional()
  @IsString()
  PUSHER_KEY?: string;

  @IsOptional()
  @IsString()
  PUSHER_SECRET?: string;

  @IsOptional()
  @IsString()
  PUSHER_CLUSTER?: string;

  // Stripe
  @IsBoolean()
  STRIPE_ENABLED: boolean = false;

  @IsOptional()
  @IsString()
  STRIPE_SECRET_KEY?: string;

  @IsOptional()
  @IsString()
  STRIPE_PUBLISHABLE_KEY?: string;

  @IsOptional()
  @IsString()
  STRIPE_WEBHOOK_SECRET?: string;

  // Super Admin
  @IsOptional()
  @IsString()
  SUPER_ADMIN_EMAIL?: string;

  @IsOptional()
  @IsString()
  SUPER_ADMIN_PASSWORD?: string;

  // Installation
  @IsString()
  INSTALLATION_NAME: string = 'Chatwoot';

  @IsString()
  INSTALLATION_ENV: string = 'development';
}

export function validate(config: Record<string, unknown>): EnvironmentVariables {
  // Convert string values to appropriate types
  const parsed: Record<string, unknown> = {
    ...config,
    PORT: parseInt(config.PORT as string, 10) || 3000,
    DATABASE_PORT: parseInt(config.DATABASE_PORT as string, 10) || 5432,
    DATABASE_SSL: config.DATABASE_SSL === 'true',
    DATABASE_POOL_SIZE: parseInt(config.DATABASE_POOL_SIZE as string, 10) || 10,
    REDIS_PORT: parseInt(config.REDIS_PORT as string, 10) || 6379,
    REDIS_DB: parseInt(config.REDIS_DB as string, 10) || 0,
    REDIS_TLS: config.REDIS_TLS === 'true',
    RATE_LIMIT_TTL: parseInt(config.RATE_LIMIT_TTL as string, 10) || 60000,
    RATE_LIMIT_MAX: parseInt(config.RATE_LIMIT_MAX as string, 10) || 100,
    CORS_ENABLED: config.CORS_ENABLED !== 'false',
    SMTP_ENABLED: config.SMTP_ENABLED === 'true',
    SMTP_PORT: config.SMTP_PORT ? parseInt(config.SMTP_PORT as string, 10) : undefined,
    LOG_FILE_ENABLED: config.LOG_FILE_ENABLED !== 'false',
    BULL_BOARD_ENABLED: config.BULL_BOARD_ENABLED !== 'false',
    WEBSOCKET_ENABLED: config.WEBSOCKET_ENABLED !== 'false',
    FEATURE_CUSTOM_ATTRIBUTES: config.FEATURE_CUSTOM_ATTRIBUTES !== 'false',
    FEATURE_CAMPAIGNS: config.FEATURE_CAMPAIGNS !== 'false',
    FEATURE_AUTOMATIONS: config.FEATURE_AUTOMATIONS !== 'false',
    FEATURE_MACROS: config.FEATURE_MACROS !== 'false',
    FEATURE_AGENT_BOTS: config.FEATURE_AGENT_BOTS !== 'false',
    FEATURE_SLA: config.FEATURE_SLA !== 'false',
    PUSHER_ENABLED: config.PUSHER_ENABLED === 'true',
    STRIPE_ENABLED: config.STRIPE_ENABLED === 'true',
  };

  const validatedConfig = plainToClass(EnvironmentVariables, parsed, {
    enableImplicitConversion: true,
  });

  const errors = validateSync(validatedConfig, {
    skipMissingProperties: false,
  });

  if (errors.length > 0) {
    throw new Error(`Environment validation failed:\n${errors.toString()}`);
  }

  return validatedConfig;
}
