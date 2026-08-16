import { createHash } from 'node:crypto';
import { readdir, readFile } from 'node:fs/promises';
import { basename, extname, join, relative, resolve } from 'node:path';
import pg from 'pg';
import { tenantKeySchema, type TenantKey } from './domain.js';

const databaseUrl = process.env.DATABASE_URL;
const tenant = process.argv[2] as TenantKey | undefined;
const root = process.argv[3] ? resolve(process.argv[3]) : undefined;
if (!databaseUrl) throw new Error('DATABASE_URL is required');
if (!tenant || !tenantKeySchema.safeParse(tenant).success) throw new Error(`Tenant required: ${tenantKeySchema.options.join('|')}`);
if (!root) throw new Error('Knowledge directory required');

async function files(directory: string): Promise<string[]> {
  const entries = await readdir(directory, { withFileTypes: true });
  const nested = await Promise.all(entries.map(entry => entry.isDirectory() ? files(join(directory, entry.name)) : [join(directory, entry.name)]));
  return nested.flat().filter(file => ['.md', '.txt', '.json'].includes(extname(file).toLowerCase())).sort();
}

function chunks(content: string, size = 3_500): string[] {
  const paragraphs = content.replace(/\r\n/g, '\n').split(/\n{2,}/);
  const result: string[] = [];
  let current = '';
  for (const paragraph of paragraphs) {
    if (current && current.length + paragraph.length + 2 > size) {
      result.push(current.trim());
      current = '';
    }
    current += `${current ? '\n\n' : ''}${paragraph}`;
  }
  if (current.trim()) result.push(current.trim());
  return result;
}

const pool = new pg.Pool({ connectionString: databaseUrl });
try {
  const sourceFiles = await files(root);
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query('DELETE FROM agent_knowledge_documents WHERE tenant_key = $1', [tenant]);
    for (const file of sourceFiles) {
      const raw = await readFile(file, 'utf8');
      const content = extname(file).toLowerCase() === '.json' ? JSON.stringify(JSON.parse(raw), null, 2) : raw;
      const sourceId = relative(root, file);
      for (const chunk of chunks(content)) {
        const contentHash = createHash('sha256').update(chunk).digest('hex');
        await client.query(
          `INSERT INTO agent_knowledge_documents (tenant_key, source_id, title, content, metadata, content_hash)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [tenant, sourceId, basename(file, extname(file)), chunk, { path: sourceId }, contentHash]
        );
      }
    }
    await client.query('COMMIT');
    console.log(`Ingested ${sourceFiles.length} sources for ${tenant}`);
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
} finally {
  await pool.end();
}
