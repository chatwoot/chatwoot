class AddLargeEmbeddingToAutonomiaKnowledge < ActiveRecord::Migration[7.0]
  # B1 (Onda 6) — coluna de embedding grande p/ o upgrade text-embedding-3-large @ 3072 dims, SEM
  # regressão: a coluna legada `embedding vector(1536)` (3-small) segue servindo o retrieval até o
  # cutover; o backfill preenche `embedding_large` e só então a config global vira 3-large. 3072 dims
  # excede o teto 2000 do índice sobre `vector`; usamos `halfvec(3072)` (16-bit) + índice hnsw, que a
  # extensão pgvector >= 0.7.0 suporta. SQL cru de propósito: as gems `neighbor 0.2.3` / `pgvector
  # 0.1.1` desta instalação NÃO conhecem o tipo halfvec — subi-las mexeria no `neighbor` que o Captain
  # também usa (risco cross-feature). Isolando via SQL, a gem fica intocada p/ a coluna legada/Captain.
  def up
    ensure_pgvector_supports_halfvec!
    execute 'ALTER TABLE autonomia_agent_knowledge ADD COLUMN IF NOT EXISTS embedding_large halfvec(3072)'
    execute <<~SQL.squish
      CREATE INDEX IF NOT EXISTS idx_autonomia_knowledge_embedding_large
      ON autonomia_agent_knowledge USING hnsw (embedding_large halfvec_cosine_ops)
    SQL
  end

  def down
    execute 'DROP INDEX IF EXISTS idx_autonomia_knowledge_embedding_large'
    execute 'ALTER TABLE autonomia_agent_knowledge DROP COLUMN IF EXISTS embedding_large'
  end

  private

  # Falha ALTO e CLARO se a extensão for antiga — nunca cria uma coluna halfvec sem suporte (o erro
  # cru do Postgres seria obscuro). Em prod isto roda no deploy; se abortar aqui, o operador atualiza
  # a extensão pgvector (>= 0.7.0) antes de repetir — decisão de infra consciente, não silenciosa.
  def ensure_pgvector_supports_halfvec!
    version = select_value("SELECT extversion FROM pg_extension WHERE extname = 'vector'")
    raise "pgvector extension not installed (enable_extension 'vector' first)" if version.blank?
    return if Gem::Version.new(version) >= Gem::Version.new('0.7.0')

    raise "pgvector #{version} does not support halfvec; upgrade the extension to >= 0.7.0 before " \
          'this migration (3-large @ 3072 dims needs halfvec + hnsw).'
  end
end
