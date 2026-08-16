import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import pg from 'pg';

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) throw new Error('DATABASE_URL is required');
const pool = new pg.Pool({ connectionString: databaseUrl });
try {
  const sql = await readFile(resolve('migrations/001_knowledge.sql'), 'utf8');
  await pool.query(sql);
  console.log('Knowledge schema is ready');
} finally {
  await pool.end();
}
