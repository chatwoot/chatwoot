class AddUniqueIndexToKnowledgeSources < ActiveRecord::Migration[7.0]
  def change
    remove_index :knowledge_sources, :ai_agent_id if index_exists?(:knowledge_sources, :ai_agent_id)
    add_index :knowledge_sources, :ai_agent_id, unique: true
  end
end
