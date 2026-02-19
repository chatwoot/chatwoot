# frozen_string_literal: true

# Upgrade vector columns from 1536 (text-embedding-3-small) to 3072 (gemini-embedding-001)
# This migration:
#   1. Drops existing HNSW index (dimension-specific)
#   2. Clears all existing embeddings (incompatible vector spaces)
#   3. Resizes vector columns to 3072 dimensions
#   4. Recreates the HNSW index
#
# After running this migration, re-embed all documents:
#   bundle exec rake aloo:reembed_all
class UpgradeEmbeddingDimensionsTo3072 < ActiveRecord::Migration[7.0]
  def up
    # Drop dimension-specific HNSW index
    remove_index :aloo_embeddings, name: :aloo_embeddings_embedding_idx, if_exists: true

    # Clear incompatible embeddings — they must be regenerated with the new model
    execute 'TRUNCATE aloo_embeddings'

    # Resize vector columns
    change_column :aloo_embeddings, :embedding, :vector, limit: 3072
    change_column :aloo_memories, :embedding, :vector, limit: 3072

    # Recreate HNSW index for cosine similarity search
    add_index :aloo_embeddings, :embedding,
              using: :hnsw,
              opclass: :vector_cosine_ops,
              name: :aloo_embeddings_embedding_idx
  end

  def down
    remove_index :aloo_embeddings, name: :aloo_embeddings_embedding_idx, if_exists: true

    execute 'TRUNCATE aloo_embeddings'

    change_column :aloo_embeddings, :embedding, :vector, limit: 1536
    change_column :aloo_memories, :embedding, :vector, limit: 1536

    add_index :aloo_embeddings, :embedding,
              using: :hnsw,
              opclass: :vector_cosine_ops,
              name: :aloo_embeddings_embedding_idx
  end
end
