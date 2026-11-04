class AddMaxOpenConversationsToAccountUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :account_users, :max_open_conversations, :integer
  end
end
