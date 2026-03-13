class AddCaptainDocumentChunksAndChunkingProgress < ActiveRecord::Migration[7.0]
  def up
    create_document_chunks_table
    add_chunking_progress_columns
  end

  def down
    remove_chunking_progress_columns
    drop_table :captain_document_chunks
  end

  private

  def create_document_chunks_table
    create_table :captain_document_chunks do |t|
      t.bigint :document_id, null: false
      t.bigint :assistant_id, null: false
      t.bigint :account_id, null: false
      t.text :content, null: false
      t.text :context
      t.vector :embedding, limit: 1536
      t.integer :position, null: false
      t.integer :token_count
      t.column :searchable, :tsvector

      t.timestamps
    end

    add_document_chunk_indexes
  end

  def add_document_chunk_indexes
    add_index :captain_document_chunks, :document_id
    add_index :captain_document_chunks, [:document_id, :position], unique: true
    add_index :captain_document_chunks, [:account_id, :assistant_id]
    add_index :captain_document_chunks, :searchable, using: :gin
    add_index :captain_document_chunks,
              :embedding,
              using: :ivfflat,
              name: 'index_captain_document_chunks_on_embedding',
              opclass: :vector_l2_ops
  end

  def add_chunking_progress_columns
    add_column :captain_documents, :chunking_status, :integer, default: 0, null: false
    add_column :captain_documents, :expected_chunk_count, :integer, default: 0, null: false
    add_column :captain_documents, :indexed_chunk_count, :integer, default: 0, null: false
    add_column :captain_documents, :chunks_generated_at, :datetime
    add_column :captain_documents, :last_chunk_error, :text

    add_index :captain_documents, :chunking_status
    add_index :captain_documents, :chunks_generated_at
  end

  def remove_chunking_progress_columns
    remove_index :captain_documents, :chunking_status
    remove_index :captain_documents, :chunks_generated_at

    remove_column :captain_documents, :chunking_status
    remove_column :captain_documents, :expected_chunk_count
    remove_column :captain_documents, :indexed_chunk_count
    remove_column :captain_documents, :chunks_generated_at
    remove_column :captain_documents, :last_chunk_error
  end
end
