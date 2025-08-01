class AddAiAgentNameIdToKnowledgeSource < ActiveRecord::Migration[7.0]
  def change
    add_column :knowledge_source_texts, :ai_agent_name_id, :string, null: true
    add_column :knowledge_source_files, :ai_agent_name_id, :string, null: true
    add_column :knowledge_source_websites, :ai_agent_name_id, :string, null: true
    add_column :knowledge_source_qnas, :ai_agent_name_id, :string, null: true
  end
end
