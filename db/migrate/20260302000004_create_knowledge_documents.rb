# frozen_string_literal: true

class CreateKnowledgeDocuments < ActiveRecord::Migration[7.1]
  def change
    create_table :knowledge_documents do |t|
      t.references :knowledge_base, null: false, foreign_key: true, index: true
      t.references :account, null: false, foreign_key: true, index: true

      t.string :title, null: false
      t.integer :source_type, null: false, default: 0 # enum: file_upload, url, text
      t.string :source_url
      t.text :content                                   # raw text content
      t.integer :status, null: false, default: 0        # enum: pending, processing, ready, error
      t.string :content_type                            # mime type for uploads
      t.integer :file_size                              # bytes
      t.integer :chunk_count, default: 0                # number of vector chunks

      # pgvector embedding (1536 dimensions for text-embedding-3-small)
      t.vector :embedding, limit: 1536

      t.jsonb :metadata, default: {}                    # extra metadata (page count, word count, etc.)
      t.text :error_message                             # processing error details

      t.timestamps
    end

    add_index :knowledge_documents, :status
    add_index :knowledge_documents, :source_type
    add_index :knowledge_documents, :embedding, using: :ivfflat, opclass: :vector_cosine_ops,
              name: 'index_knowledge_documents_on_embedding'
  end
end
