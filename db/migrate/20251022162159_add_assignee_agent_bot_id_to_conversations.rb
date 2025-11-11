class AddAssigneeAgentBotIdToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :assignee_agent_bot_id, :bigint
    add_index :conversations, :assignee_agent_bot_id
  end
end
