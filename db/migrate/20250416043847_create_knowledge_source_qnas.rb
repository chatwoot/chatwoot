class CreateKnowledgeSourceQnas < ActiveRecord::Migration[7.0]
  def change
    create_table :knowledge_source_qnas do |t|
      t.references :knowledge_source, null: false, foreign_key: true
      t.string :question, null: false
      t.text :answer, null: false
      t.jsonb :source_config, null: false, default: {}
      t.integer :total_chunks, default: 0, null: false
      t.integer :total_chars, default: 0, null: false

      t.timestamps
    end
  end
end
