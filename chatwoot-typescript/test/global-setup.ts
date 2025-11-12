import { createTestDatabase, closeTestDatabase } from './database/test-database';

/**
 * Global setup for Vitest
 * Runs once before all tests
 *
 * Note: Database connection is optional. Tests that don't need database
 * can still run if PostgreSQL is unavailable.
 */
export async function setup(): Promise<void> {
  console.log('🔧 Setting up test environment...');

  try {
    await createTestDatabase();
    console.log('✅ Global setup complete with database');
  } catch (error) {
    console.warn('⚠️  Database connection failed - tests requiring database will be skipped');
    console.warn('   To run all tests, ensure PostgreSQL is running on localhost:5432');
    // Don't throw - allow tests that don't need database to run
  }
}

/**
 * Global teardown for Vitest
 * Runs once after all tests
 */
export async function teardown(): Promise<void> {
  console.log('🔧 Tearing down test environment...');

  try {
    await closeTestDatabase();
    console.log('✅ Global teardown complete');
  } catch (error) {
    // Silently ignore - database may not have been initialized
    console.log('✅ Global teardown complete (no database connection)');
  }
}
