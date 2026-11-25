class AddContinueOpenConversationToChannelEmail < ActiveRecord::Migration[7.1]
  def change
    add_column :channel_email, :continue_open_conversation, :boolean, default: false, null: false
  end
end
