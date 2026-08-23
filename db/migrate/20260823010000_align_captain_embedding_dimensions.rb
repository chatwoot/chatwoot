class AlignCaptainEmbeddingDimensions < ActiveRecord::Migration[7.2]
  # The configured embedding model (e.g. `liquid/lfm-2.5-embedding-350m:free` via
  # OpenRouter) returns 1024-dimension vectors, but the Captain vector columns were
  # originally created at 1536. pgvector enforces a fixed dimension, so storing the
  # produced vectors fails. Recreate the columns (and their ivfflat indexes) at 1024.
  EMBEDDING_DIMENSION = 1024

  def up
    change_embedding_dimension(1024)
  end

  def down
    change_embedding_dimension(1536)
  end

  private

  def change_embedding_dimension(dimension)
    with_timeout do
      recreate_responses_index(dimension)
      recreate_faq_suggestions_index(dimension)
      recreate_article_embeddings_index(dimension)
    end
  end

  def with_timeout
    # ivfflat index recreation on empty/dev tables is fast, but guard against long
    # locks on larger datasets.
    execute 'SET statement_timeout = 0'
    yield
    execute 'RESET statement_timeout'
  end

  def recreate_responses_index(dimension)
    remove_index :captain_assistant_responses, name: 'vector_idx_knowledge_entries_embedding'
    change_column :captain_assistant_responses, :embedding, :vector, limit: dimension
    add_index :captain_assistant_responses, :embedding,
              using: :ivfflat,
              name: 'vector_idx_knowledge_entries_embedding',
              opclass: :vector_l2_ops
  end

  def recreate_faq_suggestions_index(dimension)
    remove_index :captain_faq_suggestions, name: 'vector_idx_captain_faq_suggestions_embedding'
    change_column :captain_faq_suggestions, :embedding, :vector, limit: dimension
    add_index :captain_faq_suggestions, :embedding,
              using: :ivfflat,
              name: 'vector_idx_captain_faq_suggestions_embedding',
              opclass: :vector_cosine_ops
  end

  def recreate_article_embeddings_index(dimension)
    remove_index :article_embeddings, name: 'index_article_embeddings_on_embedding'
    change_column :article_embeddings, :embedding, :vector, limit: dimension
    add_index :article_embeddings, :embedding,
              using: :ivfflat,
              name: 'index_article_embeddings_on_embedding'
  end
end
