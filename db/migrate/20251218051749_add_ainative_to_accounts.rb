class AddAinativeToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :ainative_project_id, :string
    add_column :accounts, :ainative_api_key_encrypted, :string
    add_column :accounts, :ainative_settings, :jsonb, default: {
      embeddings_model: 'BAAI/bge-small-en-v1.5',
      vector_dimensions: 384,
      auto_indexing: true,
      features: {
        semantic_search: true,
        smart_suggestions: true,
        agent_memory: true
      }
    }

    add_index :accounts, :ainative_project_id, unique: true
  end
end
