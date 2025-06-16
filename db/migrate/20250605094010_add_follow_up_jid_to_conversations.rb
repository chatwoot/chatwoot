class AddFollowUpJidToConversations < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :follow_up_jid, :string
  end
end
