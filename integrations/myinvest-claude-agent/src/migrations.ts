import { createHash } from 'node:crypto'
import { readdir, readFile } from 'node:fs/promises'
import { join } from 'node:path'

interface QueryResult<Row> {
  rows: Row[]
}
interface MigrationClient {
  query<Row extends Record<string, unknown>>(
    text: string,
    values?: readonly unknown[],
  ): Promise<QueryResult<Row>>
}

interface MigrationPool {
  connect(): Promise<MigrationClient & { release(): void }>
}

interface AppliedMigration extends Record<string, unknown> {
  checksum: string
}

export async function runMigrations(pool: MigrationPool, directory: string): Promise<string[]> {
  const client = await pool.connect()
  const applied: string[] = []
  try {
    await client.query("SELECT pg_advisory_lock(hashtext('myinvest_agent_migrations'))")
    await client.query(`CREATE TABLE IF NOT EXISTS agent_schema_migrations (
      version text PRIMARY KEY,
      checksum text NOT NULL,
      applied_at timestamptz NOT NULL DEFAULT now()
    )`)

    const filenames = (await readdir(directory))
      .filter((filename) => /^\d{3}_[a-z0-9_]+\.sql$/.test(filename))
      .sort()
    if (filenames.length === 0) throw new Error('No migrations found')

    for (const filename of filenames) {
      const sql = await readFile(join(directory, filename), 'utf8')
      const checksum = createHash('sha256').update(sql).digest('hex')
      const existing = await client.query<AppliedMigration>(
        'SELECT checksum FROM agent_schema_migrations WHERE version = $1',
        [filename],
      )
      if (existing.rows[0]) {
        if (existing.rows[0].checksum !== checksum) {
          throw new Error(`Migration checksum mismatch: ${filename}`)
        }
        continue
      }

      await client.query('BEGIN')
      try {
        await client.query(sql)
        await client.query(
          'INSERT INTO agent_schema_migrations (version, checksum) VALUES ($1, $2)',
          [filename, checksum],
        )
        await client.query('COMMIT')
        applied.push(filename)
      } catch (error) {
        await client.query('ROLLBACK')
        throw error
      }
    }
  } finally {
    try {
      await client.query("SELECT pg_advisory_unlock(hashtext('myinvest_agent_migrations'))")
    } finally {
      client.release()
    }
  }
  return applied
}
