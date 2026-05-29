class AddLastResolvedMessageIdToConversations < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :last_resolved_message_id, :integer
  end
end
