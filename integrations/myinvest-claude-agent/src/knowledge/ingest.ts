import { createHash } from 'node:crypto'
import { lstat, readdir, readFile, realpath } from 'node:fs/promises'
import { basename, extname, join, relative, sep } from 'node:path'
import { z } from 'zod'
import type { TenantKey } from '../domain.js'

export const sourceNamespaceSchema = z.string().regex(/^[a-z0-9][a-z0-9._-]{0,127}$/)

interface QueryResult<Row> {
  rows: Row[]
}

interface TransactionClient {
  query<Row extends Record<string, unknown>>(
    text: string,
    values?: readonly unknown[],
  ): Promise<QueryResult<Row>>
  release(): void
}

interface PoolLike {
  connect(): Promise<TransactionClient>
}

interface ApprovedChunk {
  sourceId: string
  title: string
  content: string
  contentHash: string
}

async function approvedFiles(directory: string, approvedRoot: string): Promise<string[]> {
  const directoryStat = await lstat(directory)
  const resolvedDirectory = await realpath(directory)
  if (
    !directoryStat.isDirectory() ||
    directoryStat.isSymbolicLink() ||
    (resolvedDirectory !== approvedRoot && !resolvedDirectory.startsWith(`${approvedRoot}${sep}`))
  ) {
    throw new Error('Approved knowledge path escapes its source root')
  }
  const entries = await readdir(directory, { withFileTypes: true })
  if (entries.some((entry) => entry.name.startsWith('.'))) {
    throw new Error('Hidden files are not allowed in approved knowledge')
  }
  if (
    entries.some((entry) =>
      [
        'manifest.json',
        'archive-manifest.json',
        'contacts.ndjson',
        'conversations.ndjson',
        'messages.ndjson',
        'source_events.ndjson',
        'source_threads.ndjson',
      ].includes(entry.name),
    )
  ) {
    throw new Error('History/export bundles cannot be ingested as approved knowledge')
  }
  if (entries.some((entry) => entry.isSymbolicLink())) {
    throw new Error('Symbolic links are not allowed in approved knowledge')
  }
  const nested = await Promise.all(
    entries.map((entry) =>
      entry.isDirectory()
        ? approvedFiles(join(directory, entry.name), approvedRoot)
        : [join(directory, entry.name)],
    ),
  )
  return nested
    .flat()
    .filter((file) => ['.md', '.txt'].includes(extname(file).toLowerCase()))
    .sort()
}

export function splitKnowledge(content: string, size = 3_500): string[] {
  const paragraphs = content.replace(/\r\n/g, '\n').split(/\n{2,}/)
  const result: string[] = []
  let current = ''
  for (const paragraph of paragraphs) {
    if (paragraph.length > size) {
      if (current.trim()) result.push(current.trim())
      current = ''
      for (let offset = 0; offset < paragraph.length; offset += size) {
        const chunk = paragraph.slice(offset, offset + size).trim()
        if (chunk) result.push(chunk)
      }
      continue
    }
    if (current && current.length + paragraph.length + 2 > size) {
      result.push(current.trim())
      current = ''
    }
    current += `${current ? '\n\n' : ''}${paragraph}`
  }
  if (current.trim()) result.push(current.trim())
  return result
}

async function loadChunks(root: string): Promise<{ chunks: ApprovedChunk[]; sourceCount: number }> {
  const rootStat = await lstat(root)
  if (!rootStat.isDirectory() || rootStat.isSymbolicLink()) {
    throw new Error('Approved knowledge root must be a regular directory')
  }
  const approvedRoot = await realpath(root)
  const files = await approvedFiles(root, approvedRoot)
  if (files.length === 0) throw new Error('Approved knowledge directory has no .md or .txt sources')
  const chunks: ApprovedChunk[] = []
  for (const file of files) {
    const fileStat = await lstat(file)
    const resolvedFile = await realpath(file)
    if (
      !fileStat.isFile() ||
      fileStat.isSymbolicLink() ||
      !resolvedFile.startsWith(`${approvedRoot}${sep}`) ||
      fileStat.size > 5_000_000
    ) {
      throw new Error('Approved knowledge source is not a regular file or exceeds 5 MB')
    }
    const sourceId = relative(root, file)
    const raw = await readFile(file, 'utf8')
    if (/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/.test(raw)) {
      throw new Error('Approved knowledge source contains control bytes')
    }
    for (const content of splitKnowledge(raw)) {
      chunks.push({
        sourceId,
        title: basename(file, extname(file)),
        content,
        contentHash: createHash('sha256').update(content).digest('hex'),
      })
    }
  }
  if (chunks.length === 0) throw new Error('Approved knowledge sources contain no text')
  return { chunks, sourceCount: files.length }
}

export async function ingestApprovedDirectory(
  pool: PoolLike,
  tenantKey: TenantKey,
  sourceNamespace: string,
  root: string,
): Promise<{ sourceCount: number; chunkCount: number; batchId: string }> {
  const namespace = sourceNamespaceSchema.parse(sourceNamespace)
  const loaded = await loadChunks(root)
  const batchId = createHash('sha256')
    .update(loaded.chunks.map((chunk) => `${chunk.sourceId}\0${chunk.contentHash}`).join('\n'))
    .digest('hex')
  const client = await pool.connect()
  try {
    await client.query('BEGIN')
    await client.query(
      `UPDATE agent_knowledge_documents
       SET active = false, publication_status = 'retired', updated_at = now()
       WHERE tenant_key = $1 AND source_namespace = $2`,
      [tenantKey, namespace],
    )
    for (const chunk of loaded.chunks) {
      await client.query(
        `INSERT INTO agent_knowledge_documents
           (tenant_key, source_namespace, source_id, title, content, metadata, content_hash,
            publication_status, active, ingest_batch_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7, 'published', true, $8)
         ON CONFLICT (tenant_key, source_namespace, source_id, content_hash)
         DO UPDATE SET title = EXCLUDED.title,
                       content = EXCLUDED.content,
                       metadata = EXCLUDED.metadata,
                       publication_status = 'published',
                       active = true,
                       ingest_batch_id = EXCLUDED.ingest_batch_id,
                       updated_at = now()`,
        [
          tenantKey,
          namespace,
          chunk.sourceId,
          chunk.title,
          chunk.content,
          { path: chunk.sourceId, source_namespace: namespace },
          chunk.contentHash,
          batchId,
        ],
      )
    }
    await client.query('COMMIT')
  } catch (error) {
    await client.query('ROLLBACK')
    throw error
  } finally {
    client.release()
  }
  return { sourceCount: loaded.sourceCount, chunkCount: loaded.chunks.length, batchId }
}
