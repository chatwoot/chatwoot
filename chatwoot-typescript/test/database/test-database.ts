import { DataSource } from 'typeorm';
import { ConfigService } from '@nestjs/config';
import { config } from 'dotenv';
import { resolve } from 'path';

// Load test environment variables
config({ path: resolve(__dirname, '../../.env.test') });

let testDataSource: DataSource | null = null;

export async function createTestDatabase(): Promise<DataSource> {
  const configService = new ConfigService();

  // Create DataSource with test configuration
  testDataSource = new DataSource({
    type: 'postgres',
    host: configService.get<string>('DATABASE_HOST', 'localhost'),
    port: configService.get<number>('DATABASE_PORT', 5432),
    username: configService.get<string>('DATABASE_USERNAME', 'postgres'),
    password: configService.get<string>('DATABASE_PASSWORD', 'postgres'),
    database: configService.get<string>('DATABASE_NAME', 'chatwoot_test'),
    entities: [resolve(__dirname, '../../src/**/*.entity{.ts,.js}')],
    synchronize: true, // Auto-create schema for tests
    dropSchema: true, // Clean slate each run
    logging: false, // Disable logging for tests
    poolSize: 5,
  });

  try {
    await testDataSource.initialize();
    console.log('✅ Test database connected and initialized');
    return testDataSource;
  } catch (error) {
    console.error('❌ Failed to connect to test database:', error);
    throw error;
  }
}

export async function closeTestDatabase(): Promise<void> {
  if (testDataSource?.isInitialized) {
    await testDataSource.destroy();
    testDataSource = null;
    console.log('✅ Test database connection closed');
  }
}

export function getTestDataSource(): DataSource {
  if (!testDataSource || !testDataSource.isInitialized) {
    throw new Error('Test database not initialized. Call createTestDatabase() first.');
  }
  return testDataSource;
}
