import { resolve } from 'node:path'
import pg from 'pg'
import { tenantKeySchema } from './domain.js'
import { ingestApprovedDirectory, sourceNamespaceSchema } from './knowledge/ingest.js'

const databaseUrl = process.env.DATABASE_URL
const tenantResult = tenantKeySchema.safeParse(process.argv[2])
const sourceResult = sourceNamespaceSchema.safeParse(process.argv[3])
const root = process.argv[4] ? resolve(process.argv[4]) : undefined

if (!databaseUrl) throw new Error('DATABASE_URL is required')
if (!tenantResult.success) throw new Error(`Tenant required: ${tenantKeySchema.options.join('|')}`)
if (!sourceResult.success) throw new Error('Stable source namespace required')
if (!root) throw new Error('Approved knowledge directory required')

const pool = new pg.Pool({ connectionString: databaseUrl })
try {
  const result = await ingestApprovedDirectory(pool, tenantResult.data, sourceResult.data, root)
  console.log(JSON.stringify({ event: 'approved_knowledge_ingested', sources: result.sourceCount }))
} finally {
  await pool.end()
}
