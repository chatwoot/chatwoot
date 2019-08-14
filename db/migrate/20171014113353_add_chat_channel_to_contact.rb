class AddChatChannelToContact < ActiveRecord::Migration[5.0]
  def change
    add_column :contacts, :chat_channel, :string
  end
end
