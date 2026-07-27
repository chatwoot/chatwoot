class AddKnowledgeMapToCaptainAssistants < ActiveRecord::Migration[7.1]
  def change
    change_table :captain_assistants, bulk: true do |t|
      t.jsonb :knowledge_map, default: {}, null: false
      t.string :knowledge_map_source_digest
      t.datetime :knowledge_map_built_at
    end
  end
end
