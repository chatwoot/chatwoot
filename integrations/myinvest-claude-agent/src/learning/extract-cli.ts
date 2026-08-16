import { resolve } from 'node:path'
import pg from 'pg'
import { extractCandidatesFromBundle } from './extractor.js'
import { storeExtractedCandidates } from './repository.js'

const databaseUrl = process.env.DATABASE_URL
const bundlePath = process.argv[2] ? resolve(process.argv[2]) : undefined
if (!databaseUrl) throw new Error('DATABASE_URL is required')
if (!bundlePath) throw new Error('HubSpot v2 bundle directory required')

const extraction = await extractCandidatesFromBundle(bundlePath)
const pool = new pg.Pool({ connectionString: databaseUrl })
try {
  const stored = await storeExtractedCandidates(pool, extraction.candidates)
  console.log(
    JSON.stringify({
      event: 'knowledge_candidates_quarantined',
      examined_pairs: extraction.examinedPairs,
      candidates: extraction.candidates.length,
      inserted: stored.inserted,
      refreshed: stored.refreshed,
      rejected_pairs: extraction.rejectedPairs,
    }),
  )
} finally {
  await pool.end()
}
