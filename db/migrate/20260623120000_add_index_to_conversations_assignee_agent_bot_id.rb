class AddIndexToConversationsAssigneeAgentBotId < ActiveRecord::Migration[7.1]
  def change
    add_index :conversations, :assignee_agent_bot_id
  end
end
