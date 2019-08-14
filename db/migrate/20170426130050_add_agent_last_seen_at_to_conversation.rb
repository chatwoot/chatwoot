class AddAgentLastSeenAtToConversation < ActiveRecord::Migration[5.0]
  def change
    add_column :conversations, :agent_last_seen_at, :datetime
  end
end
