class AddSenderToConversation < ActiveRecord::Migration[5.0]
  def change
    add_column :conversations, :sender_id, :integer
  end
end
