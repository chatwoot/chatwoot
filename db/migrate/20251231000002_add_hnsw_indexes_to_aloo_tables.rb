# frozen_string_literal: true

class AddHnswIndexesToAlooTables < ActiveRecord::Migration[7.0]
  def up
    # HNSW (Hierarchical Navigable Small World) indexes for fast approximate nearest neighbor search
    # Parameters:
    # - m = 16: Maximum number of connections per layer (higher = better recall, more memory)
    # - ef_construction = 64: Size of dynamic candidate list during index construction (higher = better index quality)
    # - vector_cosine_ops: Use cosine similarity (1 - cosine distance)

    # Index for embeddings table (knowledge base search)
    execute <<-SQL
      CREATE INDEX IF NOT EXISTS aloo_embeddings_embedding_idx
      ON aloo_embeddings
      USING hnsw (embedding vector_cosine_ops)
      WITH (m = 16, ef_construction = 64);
    SQL

    # Index for memories table (memory retrieval)
    execute <<-SQL
      CREATE INDEX IF NOT EXISTS aloo_memories_embedding_idx
      ON aloo_memories
      USING hnsw (embedding vector_cosine_ops)
      WITH (m = 16, ef_construction = 64);
    SQL
  end

  def down
    execute 'DROP INDEX IF EXISTS aloo_embeddings_embedding_idx'
    execute 'DROP INDEX IF EXISTS aloo_memories_embedding_idx'
  end
end
