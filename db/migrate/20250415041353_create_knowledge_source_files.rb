class CreateKnowledgeSourceFiles < ActiveRecord::Migration[7.0]
  def change
    create_table :knowledge_source_files do |t|
      t.references :knowledge_source, null: false, foreign_key: true
      t.string :loader_id, null: false
      t.string :file_name
      t.string :file_type
      t.integer :file_size
      t.integer :total_chunks, default: 0, null: false
      t.integer :total_chars, default: 0, null: false
      t.jsonb :source_config, null: false, default: {}

      t.timestamps
    end
  end
end
