class ReplaceCaptainAssistantResponseEmbeddingIndexWithCosine < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  OLD_INDEX_NAME = 'vector_idx_knowledge_entries_embedding'.freeze
  NEW_INDEX_NAME = 'vector_idx_captain_assistant_responses_embedding_cosine'.freeze
  MINIMUM_PGVECTOR_VERSION = Gem::Version.new('0.8.0')

  def up
    ensure_iterative_scans_supported!

    add_index :captain_assistant_responses,
              :embedding,
              using: :ivfflat,
              opclass: :vector_cosine_ops,
              name: NEW_INDEX_NAME,
              algorithm: :concurrently
    remove_index :captain_assistant_responses, name: OLD_INDEX_NAME, algorithm: :concurrently
  end

  def down
    add_index :captain_assistant_responses,
              :embedding,
              using: :ivfflat,
              opclass: :vector_l2_ops,
              name: OLD_INDEX_NAME,
              algorithm: :concurrently
    remove_index :captain_assistant_responses, name: NEW_INDEX_NAME, algorithm: :concurrently
  end

  private

  def ensure_iterative_scans_supported!
    installed_version = Gem::Version.new(select_value("SELECT extversion FROM pg_extension WHERE extname = 'vector'"))
    return if installed_version >= MINIMUM_PGVECTOR_VERSION

    raise StandardError, "pgvector #{MINIMUM_PGVECTOR_VERSION} or newer is required for filtered FAQ search"
  end
end
