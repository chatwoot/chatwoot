class CreateResponses < ActiveRecord::Migration[7.0]
  def change
    create_response_sources
    create_response_documents
    create_responses
  end

  private

  def create_response_sources
    create_table :response_sources do |t|
      t.integer :source_type, null: false, default: 0
      t.string :name, null: false
      t.string :source_link
      t.references :source_model, polymorphic: true
      t.bigint :account_id, null: false
      t.bigint :inbox_id, null: false
      t.timestamps
    end
  end

  def create_response_documents
    create_table :response_documents do |t|
      t.bigint :response_source_id, null: false
      t.string :document_link
      t.references :document, polymorphic: true
      t.text :content
      t.bigint :account_id, null: false
      t.timestamps
    end

    add_index :response_documents, :response_source_id
  end

  def create_responses
    create_table :responses do |t|
      t.bigint :response_document_id
      t.string :question, null: false
      t.text :answer, null: false
      t.bigint :account_id, null: false
      t.vector :embedding, limit: 1536
      t.timestamps
    end

    add_index :responses, :response_document_id
    add_index :responses, :embedding, using: :ivfflat, opclass: :vector_l2_ops
  end
end
