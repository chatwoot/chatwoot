import { registerAs } from '@nestjs/config';
import { Environment, StorageType, LogLevel } from './env.validation';

export const appConfig = registerAs('app', () => ({
  nodeEnv: process.env.NODE_ENV as Environment,
  port: parseInt(process.env.PORT || '3000', 10),
  name: process.env.APP_NAME || 'Chatwoot',
  frontendUrl: process.env.FRONTEND_URL,
  apiVersion: process.env.API_VERSION || 'v1',
}));

export const databaseConfig = registerAs('database', () => ({
  host: process.env.DATABASE_HOST,
  port: parseInt(process.env.DATABASE_PORT || '5432', 10),
  name: process.env.DATABASE_NAME,
  username: process.env.DATABASE_USERNAME,
  password: process.env.DATABASE_PASSWORD,
  ssl: process.env.DATABASE_SSL === 'true',
  poolSize: parseInt(process.env.DATABASE_POOL_SIZE || '10', 10),
}));

export const redisConfig = registerAs('redis', () => ({
  host: process.env.REDIS_HOST,
  port: parseInt(process.env.REDIS_PORT || '6379', 10),
  password: process.env.REDIS_PASSWORD,
  db: parseInt(process.env.REDIS_DB || '0', 10),
  tls: process.env.REDIS_TLS === 'true',
}));

export const authConfig = registerAs('auth', () => ({
  jwtSecret: process.env.JWT_SECRET,
  jwtExpiration: process.env.JWT_EXPIRATION || '7d',
  refreshTokenExpiration: process.env.REFRESH_TOKEN_EXPIRATION || '30d',
  sessionSecret: process.env.SESSION_SECRET,
}));

export const rateLimitConfig = registerAs('rateLimit', () => ({
  ttl: parseInt(process.env.RATE_LIMIT_TTL || '60000', 10),
  max: parseInt(process.env.RATE_LIMIT_MAX || '100', 10),
}));

export const corsConfig = registerAs('cors', () => ({
  enabled: process.env.CORS_ENABLED !== 'false',
  origin: process.env.CORS_ORIGIN,
}));

export const storageConfig = registerAs('storage', () => ({
  type: (process.env.STORAGE_TYPE as StorageType) || StorageType.Local,
  path: process.env.STORAGE_PATH,
  aws: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
    region: process.env.AWS_REGION,
    s3Bucket: process.env.AWS_S3_BUCKET,
    s3Endpoint: process.env.AWS_S3_ENDPOINT,
  },
}));

export const emailConfig = registerAs('email', () => ({
  enabled: process.env.SMTP_ENABLED === 'true',
  smtp: {
    host: process.env.SMTP_HOST,
    port: parseInt(process.env.SMTP_PORT || '587', 10),
    username: process.env.SMTP_USERNAME,
    password: process.env.SMTP_PASSWORD,
  },
  from: {
    email: process.env.SMTP_FROM_EMAIL || 'support@chatwoot.com',
    name: process.env.SMTP_FROM_NAME || 'Chatwoot Support',
  },
}));

export const loggingConfig = registerAs('logging', () => ({
  level: (process.env.LOG_LEVEL as LogLevel) || LogLevel.Info,
  fileEnabled: process.env.LOG_FILE_ENABLED !== 'false',
  filePath: process.env.LOG_FILE_PATH || './logs',
}));

export const bullConfig = registerAs('bull', () => ({
  boardEnabled: process.env.BULL_BOARD_ENABLED !== 'false',
  boardPath: process.env.BULL_BOARD_PATH || '/admin/queues',
}));

export const websocketConfig = registerAs('websocket', () => ({
  enabled: process.env.WEBSOCKET_ENABLED !== 'false',
  path: process.env.WEBSOCKET_PATH || '/cable',
}));

export const slackConfig = registerAs('slack', () => ({
  clientId: process.env.SLACK_CLIENT_ID,
  clientSecret: process.env.SLACK_CLIENT_SECRET,
  verificationToken: process.env.SLACK_VERIFICATION_TOKEN,
}));

export const facebookConfig = registerAs('facebook', () => ({
  appId: process.env.FACEBOOK_APP_ID,
  appSecret: process.env.FACEBOOK_APP_SECRET,
  verifyToken: process.env.FACEBOOK_VERIFY_TOKEN,
}));

export const whatsappConfig = registerAs('whatsapp', () => ({
  cloudApiAccessToken: process.env.WHATSAPP_CLOUD_API_ACCESS_TOKEN,
  cloudApiPhoneNumberId: process.env.WHATSAPP_CLOUD_API_PHONE_NUMBER_ID,
  cloudApiVerifyToken: process.env.WHATSAPP_CLOUD_API_VERIFY_TOKEN,
}));

export const twilioConfig = registerAs('twilio', () => ({
  accountSid: process.env.TWILIO_ACCOUNT_SID,
  authToken: process.env.TWILIO_AUTH_TOKEN,
  phoneNumber: process.env.TWILIO_PHONE_NUMBER,
}));

export const sentryConfig = registerAs('sentry', () => ({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.SENTRY_ENVIRONMENT || 'development',
}));

export const featureFlagsConfig = registerAs('featureFlags', () => ({
  customAttributes: process.env.FEATURE_CUSTOM_ATTRIBUTES !== 'false',
  campaigns: process.env.FEATURE_CAMPAIGNS !== 'false',
  automations: process.env.FEATURE_AUTOMATIONS !== 'false',
  macros: process.env.FEATURE_MACROS !== 'false',
  agentBots: process.env.FEATURE_AGENT_BOTS !== 'false',
  sla: process.env.FEATURE_SLA !== 'false',
}));

export const encryptionConfig = registerAs('encryption', () => ({
  key: process.env.ENCRYPTION_KEY,
}));

export const openaiConfig = registerAs('openai', () => ({
  apiKey: process.env.OPENAI_API_KEY,
  model: process.env.OPENAI_MODEL || 'gpt-4',
}));

export const pusherConfig = registerAs('pusher', () => ({
  enabled: process.env.PUSHER_ENABLED === 'true',
  appId: process.env.PUSHER_APP_ID,
  key: process.env.PUSHER_KEY,
  secret: process.env.PUSHER_SECRET,
  cluster: process.env.PUSHER_CLUSTER || 'mt1',
}));

export const stripeConfig = registerAs('stripe', () => ({
  enabled: process.env.STRIPE_ENABLED === 'true',
  secretKey: process.env.STRIPE_SECRET_KEY,
  publishableKey: process.env.STRIPE_PUBLISHABLE_KEY,
  webhookSecret: process.env.STRIPE_WEBHOOK_SECRET,
}));

export const superAdminConfig = registerAs('superAdmin', () => ({
  email: process.env.SUPER_ADMIN_EMAIL,
  password: process.env.SUPER_ADMIN_PASSWORD,
}));

export const installationConfig = registerAs('installation', () => ({
  name: process.env.INSTALLATION_NAME || 'Chatwoot',
  env: process.env.INSTALLATION_ENV || 'development',
}));

export default [
  appConfig,
  databaseConfig,
  redisConfig,
  authConfig,
  rateLimitConfig,
  corsConfig,
  storageConfig,
  emailConfig,
  loggingConfig,
  bullConfig,
  websocketConfig,
  slackConfig,
  facebookConfig,
  whatsappConfig,
  twilioConfig,
  sentryConfig,
  featureFlagsConfig,
  encryptionConfig,
  openaiConfig,
  pusherConfig,
  stripeConfig,
  superAdminConfig,
  installationConfig,
];
