import pg from 'pg'
import { approveCandidate, publishCandidate, rejectCandidate } from './repository.js'

const databaseUrl = process.env.DATABASE_URL
const action = process.argv[2]
const candidateId = process.argv[3]
if (!databaseUrl) throw new Error('DATABASE_URL is required')
if (!candidateId) throw new Error('Candidate ID required')

const pool = new pg.Pool({ connectionString: databaseUrl })
try {
  if (action === 'approve') {
    const tenant = process.argv[4]
    const actor = process.argv[5]
    if (!tenant || !actor) throw new Error('Usage: approve <candidate-id> <tenant> <reviewer>')
    await approveCandidate(pool, candidateId, tenant, actor)
  } else if (action === 'publish') {
    const actor = process.argv[4]
    if (!actor) throw new Error('Usage: publish <candidate-id> <reviewer>')
    await publishCandidate(pool, candidateId, actor)
  } else if (action === 'reject') {
    const actor = process.argv[4]
    if (!actor) throw new Error('Usage: reject <candidate-id> <reviewer>')
    await rejectCandidate(pool, candidateId, actor)
  } else {
    throw new Error('Action required: approve|publish|reject')
  }
  console.log(JSON.stringify({ event: 'knowledge_candidate_reviewed', action, candidate_id: candidateId }))
} finally {
  await pool.end()
}
