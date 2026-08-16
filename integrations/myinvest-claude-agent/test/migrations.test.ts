import { mkdtemp, writeFile } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { describe, expect, it, vi } from 'vitest'
import { runMigrations } from '../src/migrations.js'

describe('versioned migrations', () => {
  it('applies files once in order and rejects changed history', async () => {
    const root = await mkdtemp(join(tmpdir(), 'agent-migrations-'))
    await writeFile(join(root, '001_first.sql'), 'SELECT 1;', 'utf8')
    await writeFile(join(root, '002_second.sql'), 'SELECT 2;', 'utf8')
    await writeFile(join(root, '003_third.sql'), 'SELECT 3;', 'utf8')
    await writeFile(join(root, '004_fourth.sql'), 'SELECT 4;', 'utf8')
    const applied = new Map<string, string>()
    const query = vi.fn(async (sql: string, values?: readonly unknown[]) => {
      if (sql.startsWith('SELECT checksum')) {
        const checksum = applied.get(String(values?.[0]))
        return { rows: checksum ? [{ checksum }] : [] }
      }
      if (sql.startsWith('INSERT INTO agent_schema_migrations')) {
        applied.set(String(values?.[0]), String(values?.[1]))
      }
      return { rows: [] }
    })
    const pool = { connect: vi.fn().mockResolvedValue({ query, release: vi.fn() }) }

    await expect(runMigrations(pool, root)).resolves.toEqual([
      '001_first.sql',
      '002_second.sql',
      '003_third.sql',
      '004_fourth.sql',
    ])
    await expect(runMigrations(pool, root)).resolves.toEqual([])
    await writeFile(join(root, '001_first.sql'), 'SELECT 99;', 'utf8')
    await expect(runMigrations(pool, root)).rejects.toThrow(/checksum mismatch/)
  })
})
