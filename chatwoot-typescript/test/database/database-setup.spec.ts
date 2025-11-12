import { describe, it, expect } from 'vitest';
import { getTestDataSource } from './test-database';
import { cleanDatabase, resetSequences, resetDatabase } from './database-cleaner';

describe('Test Database Setup', () => {
  it('should have database connection', () => {
    const dataSource = getTestDataSource();
    expect(dataSource).toBeDefined();
    expect(dataSource.isInitialized).toBe(true);
  });

  it('should have correct database configuration', () => {
    const dataSource = getTestDataSource();
    expect(dataSource.options.type).toBe('postgres');
    expect(dataSource.options.database).toBe('chatwoot_test');
  });

  it('should be able to query database', async () => {
    const dataSource = getTestDataSource();
    const result = await dataSource.query('SELECT 1 as value');
    expect(result).toBeDefined();
    expect(result[0].value).toBe(1);
  });

  it('should have synchronize enabled for tests', () => {
    const dataSource = getTestDataSource();
    expect(dataSource.options.synchronize).toBe(true);
  });

  it('should have dropSchema enabled for tests', () => {
    const dataSource = getTestDataSource();
    expect((dataSource.options as any).dropSchema).toBe(true);
  });

  it('should clean database without errors', async () => {
    await expect(cleanDatabase()).resolves.not.toThrow();
  });

  it('should reset sequences without errors', async () => {
    await expect(resetSequences()).resolves.not.toThrow();
  });

  it('should reset database (clean + sequences) without errors', async () => {
    await expect(resetDatabase()).resolves.not.toThrow();
  });

  it('should maintain connection after database operations', async () => {
    await resetDatabase();
    const dataSource = getTestDataSource();
    expect(dataSource.isInitialized).toBe(true);

    // Verify we can still query after reset
    const result = await dataSource.query('SELECT 1 as test');
    expect(result[0].test).toBe(1);
  });
});
