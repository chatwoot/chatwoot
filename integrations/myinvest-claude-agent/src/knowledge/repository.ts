import type { KnowledgeHit, TenantKey } from '../domain.js'

interface QueryResult<Row> {
  rows: Row[]
}

interface Queryable {
  query<Row extends Record<string, unknown>>(
    text: string,
    values?: readonly unknown[],
  ): Promise<QueryResult<Row>>
}

interface KnowledgeRow extends Record<string, unknown> {
  source_id: string
  title: string
  content: string
  metadata: Record<string, unknown>
  score: number | string
}

export interface KnowledgeRepository {
  search(tenantKey: TenantKey, query: string, limit: number): Promise<KnowledgeHit[]>
}

const SEARCH_BODY = `
       SELECT source_id, title, content, metadata,
              ts_rank_cd(search_vector, input.query)::float AS score
       FROM agent_knowledge_documents, input
       WHERE tenant_key = $1
         AND publication_status = 'published'
         AND active = true
         AND search_vector @@ input.query
       ORDER BY score DESC, source_id ASC
       LIMIT $3`

// websearch_to_tsquery AND-verknuepft alle Lexeme: ein einziges unbekanntes
// Wort in einer natuerlichen Kundenfrage loescht sonst jeden Treffer.
const STRICT_QUERY = `WITH input AS (
         SELECT websearch_to_tsquery('german', $2) AS query
       )${SEARCH_BODY}`

// Fallback bei null Treffern: OR-Verknuepfung der Lexeme, das Ranking sortiert.
const RELAXED_QUERY = `WITH input AS (
         SELECT replace(plainto_tsquery('german', $2)::text, ' & ', ' | ')::tsquery AS query
       )${SEARCH_BODY}`

export class PostgresKnowledgeRepository implements KnowledgeRepository {
  constructor(private readonly database: Queryable) {}

  async search(tenantKey: TenantKey, query: string, limit: number): Promise<KnowledgeHit[]> {
    const strict = await this.runQuery(STRICT_QUERY, tenantKey, query, limit)
    if (strict.length > 0) {
      return strict
    }
    return this.runQuery(RELAXED_QUERY, tenantKey, query, limit)
  }

  private async runQuery(
    sql: string,
    tenantKey: TenantKey,
    query: string,
    limit: number,
  ): Promise<KnowledgeHit[]> {
    const result = await this.database.query<KnowledgeRow>(sql, [tenantKey, query, limit])
    return result.rows.map((row) => ({
      sourceId: row.source_id,
      title: row.title,
      content: row.content,
      metadata: row.metadata,
      score: Number(row.score),
    }))
  }
}
