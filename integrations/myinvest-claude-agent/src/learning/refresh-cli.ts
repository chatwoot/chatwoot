import { resolve } from 'node:path'
import pg from 'pg'
import { extractCandidatesFromBundle } from './extractor.js'
import {
  refreshReviewedCandidates,
  sanitizeStaleCandidates,
  storeExtractedCandidates,
} from './repository.js'

const databaseUrl = process.env.DATABASE_URL
const bundlePaths = process.argv.slice(2).map((path) => resolve(path))
if (!databaseUrl) throw new Error('DATABASE_URL is required')
if (bundlePaths.length === 0) throw new Error('At least one HubSpot v2 bundle directory is required')

const extractions = await Promise.all(bundlePaths.map((path) => extractCandidatesFromBundle(path)))
const pool = new pg.Pool({ connectionString: databaseUrl })
try {
  let inserted = 0
  let refreshed = 0
  let reviewRequired = 0
  let rejected = 0
  const namespaces = new Map<string, typeof extractions>()
  for (const extraction of extractions) {
    const grouped = namespaces.get(extraction.sourceNamespace) ?? []
    grouped.push(extraction)
    namespaces.set(extraction.sourceNamespace, grouped)
  }
  for (const [sourceNamespace, grouped] of namespaces) {
    const candidates = grouped.flatMap((extraction) => extraction.candidates)
    const redactionVersion = Math.max(...grouped.map((extraction) => extraction.redactionVersion))
    reviewRequired += await refreshReviewedCandidates(pool, candidates)
    const stored = await storeExtractedCandidates(pool, candidates)
    inserted += stored.inserted
    refreshed += stored.refreshed
    const currentCandidateKeys = candidates.flatMap((candidate) => [
      candidate.candidateKey,
      ...candidate.previousCandidateKeys,
    ])
    rejected += await sanitizeStaleCandidates(
      pool,
      sourceNamespace,
      currentCandidateKeys,
      redactionVersion,
    )
  }
  console.log(
    JSON.stringify({
      event: 'knowledge_candidate_redaction_refreshed',
      inserted,
      refreshed,
      review_required: reviewRequired,
      rejected,
      redaction_version: Math.max(...extractions.map((extraction) => extraction.redactionVersion)),
    }),
  )
} finally {
  await pool.end()
}
