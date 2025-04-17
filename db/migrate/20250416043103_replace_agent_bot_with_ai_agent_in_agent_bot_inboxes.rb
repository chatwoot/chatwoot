class ReplaceAgentBotWithAiAgentInAgentBotInboxes < ActiveRecord::Migration[6.1]
  def change
    remove_column :agent_bot_inboxes, :agent_bot_id, :integer
    add_column :agent_bot_inboxes, :ai_agent_id, :integer
    add_index :agent_bot_inboxes, :ai_agent_id
  end
end
