class AddActiveChatLimitToAccountUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :account_users, :active_chat_limit, :integer
    add_column :account_users, :active_chat_limit_enabled, :boolean, default: false, null: false
  end
end
