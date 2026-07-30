class AddChatBotToContacts < ActiveRecord::Migration[7.1]
  def change
    add_column :contacts, :chat_bot, :boolean, default: true, null: false
  end
end
