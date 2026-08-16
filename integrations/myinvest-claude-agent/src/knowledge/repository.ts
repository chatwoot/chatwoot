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

export class PostgresKnowledgeRepository implements KnowledgeRepository {
  constructor(private readonly database: Queryable) {}

  async search(tenantKey: TenantKey, query: string, limit: number): Promise<KnowledgeHit[]> {
    const result = await this.database.query<KnowledgeRow>(
      `WITH input AS (
         SELECT websearch_to_tsquery('german', $2) AS query
       )
       SELECT source_id, title, content, metadata,
              ts_rank_cd(search_vector, input.query)::float AS score
       FROM agent_knowledge_documents, input
       WHERE tenant_key = $1
         AND search_vector @@ input.query
       ORDER BY score DESC, source_id ASC
       LIMIT $3`,
      [tenantKey, query, limit],
    )
    return result.rows.map((row) => ({
      sourceId: row.source_id,
      title: row.title,
      content: row.content,
      metadata: row.metadata,
      score: Number(row.score),
    }))
  }
}
