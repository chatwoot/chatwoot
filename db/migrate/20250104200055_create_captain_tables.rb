class CreateCaptainTables < ActiveRecord::Migration[7.0]
  def up
    # Post this migration, the 'vector' extension is mandatory to run the application.
    # The extension should already be installed. If not, install it manually before running this migration.
    # setup_vector_extension - Skipped due to client/server version mismatch

    # Ensure the public schema is in the search path for the vector type
    execute('SET search_path TO public')

    create_assistants
    create_documents
    create_assistant_responses
    create_old_tables
  end

  def down
    drop_table :captain_assistant_responses if table_exists?(:captain_assistant_responses)
    drop_table :captain_documents if table_exists?(:captain_documents)
    drop_table :captain_assistants if table_exists?(:captain_assistants)
    drop_table :article_embeddings if table_exists?(:article_embeddings)

    # We are not disabling the extension here because it might be
    # used by other tables which are not part of this migration.
  end

  private

  def setup_vector_extension
    # Try to create extension, ignoring errors if it already exists or path issues

    # Check if extension already exists first
    result = execute("SELECT EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'vector')").first
    extension_exists = result.values.first == 't' || result.values.first == true

    return if extension_exists

    # Try to create using raw SQL
    execute('CREATE EXTENSION vector')
  rescue ActiveRecord::StatementInvalid => e
    # Verify the extension exists despite the error
    check_result = execute("SELECT EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'vector')").first
    has_extension = check_result.values.first == 't' || check_result.values.first == true

    # Only raise if extension truly doesn't exist
    raise StandardError, "Failed to enable 'vector' extension. Read more at https://chwt.app/v4/migration: #{e.message}" unless has_extension
  end

  def create_assistants
    create_table :captain_assistants do |t|
      t.string :name, null: false
      t.bigint :account_id, null: false
      t.string :description

      t.timestamps
    end

    add_index :captain_assistants, :account_id
    add_index :captain_assistants, [:account_id, :name], unique: true
  end

  def create_documents
    create_table :captain_documents do |t|
      t.string :name, null: false
      t.string :external_link, null: false
      t.text :content
      t.bigint :assistant_id, null: false
      t.bigint :account_id, null: false

      t.timestamps
    end

    add_index :captain_documents, :account_id
    add_index :captain_documents, :assistant_id
    add_index :captain_documents, [:assistant_id, :external_link], unique: true
  end

  def create_assistant_responses
    create_table :captain_assistant_responses do |t|
      t.string :question, null: false
      t.text :answer, null: false
      t.vector :embedding, limit: 1536
      t.bigint :assistant_id, null: false
      t.bigint :document_id
      t.bigint :account_id, null: false

      t.timestamps
    end

    add_index :captain_assistant_responses, :account_id
    add_index :captain_assistant_responses, :assistant_id
    add_index :captain_assistant_responses, :document_id
    add_index :captain_assistant_responses, :embedding, using: :ivfflat, name: 'vector_idx_knowledge_entries_embedding', opclass: :vector_l2_ops
  end

  def create_old_tables
    create_table :article_embeddings, if_not_exists: true do |t|
      t.bigint :article_id, null: false
      t.text :term, null: false
      t.vector :embedding, limit: 1536
      t.timestamps
    end
    add_index :article_embeddings, :embedding, if_not_exists: true, using: :ivfflat, opclass: :vector_l2_ops
  end
end
