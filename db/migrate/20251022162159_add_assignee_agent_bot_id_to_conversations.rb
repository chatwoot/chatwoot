class AddAssigneeAgentBotIdToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :assignee_agent_bot_id, :bigint
  end
end
