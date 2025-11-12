import { config } from 'dotenv';
import { resolve } from 'path';
import { beforeEach, afterAll, vi } from 'vitest';
import { resetDatabase } from './database/database-cleaner';
import { closeTestDatabase } from './database/test-database';

// Load test environment variables
config({ path: resolve(__dirname, '../.env.test') });

// Set NODE_ENV to test
process.env.NODE_ENV = 'test';

// Mock console methods to reduce noise in tests
global.console = {
  ...console,
  error: vi.fn(),
  warn: vi.fn(),
};

// Clean database before each test for isolation
beforeEach(async () => {
  try {
    await resetDatabase();
  } catch (error) {
    // Silently skip if database not initialized yet (e.g., for sanity tests)
    // This allows tests that don't need database to still run
  }
});

// Cleanup after all tests
afterAll(async () => {
  try {
    await closeTestDatabase();
  } catch (error) {
    // Silently skip if database was never initialized
  }
});
