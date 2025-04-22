class CreateKnowledgeSources < ActiveRecord::Migration[7.0]
  def change
    create_table :knowledge_sources do |t|
      t.references :ai_agent, null: false, foreign_key: true
      t.string :name, null: false
      t.string :store_id, null: false
      t.timestamps
    end
  end
end
