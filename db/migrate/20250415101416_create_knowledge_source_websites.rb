class CreateKnowledgeSourceWebsites < ActiveRecord::Migration[7.0]
  def change
    create_table :knowledge_source_websites do |t|
      t.references :knowledge_source, null: false, foreign_key: true
      t.string :url, null: false
      t.string :parent_url, null: false
      t.integer :total_chars, null: false
      t.integer :total_chunks, null: false
      t.string :loader_id, null: false

      t.timestamps
    end
  end
end
