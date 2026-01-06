class AddHasUnreadMessagesToConversations < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :has_unread_messages, :boolean, default: false, null: false

    add_index :conversations, %i[account_id has_unread_messages],
              where: 'has_unread_messages = true',
              name: 'index_conversations_on_account_has_unread'

    add_index :conversations, %i[inbox_id has_unread_messages],
              where: 'has_unread_messages = true',
              name: 'index_conversations_on_inbox_has_unread'
  end
end
