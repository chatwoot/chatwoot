import { resolve } from 'node:path';
import pg from 'pg';
import { runMigrations } from './migrations.js';

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) throw new Error('DATABASE_URL is required');
const pool = new pg.Pool({ connectionString: databaseUrl });
try {
  const applied = await runMigrations(pool, resolve('migrations'));
  console.log(JSON.stringify({ event: 'agent_schema_ready', migrations_applied: applied.length }));
} finally {
  await pool.end();
}
