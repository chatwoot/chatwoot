import { getTestDataSource } from './test-database';

/**
 * Truncate all tables in the test database
 * Uses CASCADE to handle foreign key constraints
 */
export async function cleanDatabase(): Promise<void> {
  const dataSource = getTestDataSource();
  const entities = dataSource.entityMetadatas;

  // Skip if no entities yet
  if (entities.length === 0) {
    return;
  }

  try {
    // Disable foreign key checks temporarily
    await dataSource.query('SET session_replication_role = replica;');

    // Truncate all tables
    for (const entity of entities) {
      if (entity.tableName) {
        await dataSource.query(`TRUNCATE TABLE "${entity.tableName}" CASCADE;`);
      }
    }

    // Re-enable foreign key checks
    await dataSource.query('SET session_replication_role = DEFAULT;');
  } catch (error) {
    console.error('Error cleaning database:', error);
    throw error;
  }
}

/**
 * Reset all sequences to start from 1
 * Useful for consistent test data IDs
 */
export async function resetSequences(): Promise<void> {
  const dataSource = getTestDataSource();
  const entities = dataSource.entityMetadatas;

  // Skip if no entities yet
  if (entities.length === 0) {
    return;
  }

  try {
    for (const entity of entities) {
      if (entity.tableName) {
        // Reset sequence if it exists
        await dataSource.query(
          `ALTER SEQUENCE IF EXISTS "${entity.tableName}_id_seq" RESTART WITH 1;`,
        );
      }
    }
  } catch (error) {
    console.error('Error resetting sequences:', error);
    throw error;
  }
}

/**
 * Complete database reset: truncate + reset sequences
 */
export async function resetDatabase(): Promise<void> {
  await cleanDatabase();
  await resetSequences();
}
