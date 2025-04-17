class CreateKnowledgeSourceTexts < ActiveRecord::Migration[7.0]
  def change
    create_table :knowledge_source_texts do |t|
      t.references :knowledge_source, null: false, foreign_key: true
      t.string :text, null: false
      t.string :loader_id, null: false
      t.integer :tab, null: false
      t.jsonb :source_config, null: false, default: {}
      t.timestamps
    end
  end
end
