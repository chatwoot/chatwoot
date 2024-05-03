class AddedBotStatusToConversations < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :bot_icon_status, :boolean, default: true
    add_column :conversations, :is_bot_connected, :boolean, default: false
  end
end
