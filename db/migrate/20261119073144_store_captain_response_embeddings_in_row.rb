class StoreCaptainResponseEmbeddingsInRow < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  INDEX_NAME = 'vector_idx_knowledge_entries_embedding'.freeze

  # FAQ search reads every embedding of an assistant. Stored out of row in TOAST, each one costs about five pages;
  # stored in the row, it costs one. Existing rows move when Migration::MoveCaptainResponseEmbeddingsInRowJob rewrites them.
  def up
    # This index uses L2 distance, but FAQ search orders by cosine distance, so Postgres never uses it.
    # A concurrent drop waits for running transactions, which can take longer than the default statement timeout.
    execute 'SET statement_timeout = 0'
    remove_index :captain_assistant_responses, name: INDEX_NAME, algorithm: :concurrently, if_exists: true
    execute 'RESET statement_timeout'
    # Production runs these statements by hand before deploying, so skip the ALTER and its lock when it is already done.
    change_embedding_storage('PLAIN') unless embedding_storage == 'p'
  end

  def down
    # Databases created with pgvector before 0.6.0, such as production, store embeddings as EXTENDED.
    change_embedding_storage('EXTENDED')
    # Building an IVFFlat index over every embedding takes far longer than the default statement timeout.
    execute 'SET statement_timeout = 0'
    add_index :captain_assistant_responses, :embedding, using: :ivfflat, opclass: :vector_l2_ops, name: INDEX_NAME,
                                                        algorithm: :concurrently
    execute 'RESET statement_timeout'
  end

  private

  def embedding_storage
    select_value("SELECT attstorage FROM pg_attribute WHERE attrelid = 'captain_assistant_responses'::regclass AND attname = 'embedding'")
  end

  # Rails has no API for column storage. SET STORAGE only changes the catalog, but it takes an ACCESS EXCLUSIVE lock,
  # so the short lock timeout stops it from queueing behind a long query and blocking FAQ searches. Rerun it if it times out.
  def change_embedding_storage(storage)
    transaction do
      execute "SET LOCAL lock_timeout = '5s'"
      execute "ALTER TABLE captain_assistant_responses ALTER COLUMN embedding SET STORAGE #{storage}"
    end
  end
end
