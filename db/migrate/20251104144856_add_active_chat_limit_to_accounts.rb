class AddActiveChatLimitToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :active_chat_limit_enabled, :boolean, default: false, null: false
    add_column :accounts, :active_chat_limit_value, :integer, default: 7
  end
end
