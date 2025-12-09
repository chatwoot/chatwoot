class AddConversationFilterModeToAccountUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :account_users, :conversation_filter_mode, :integer, default: 0, null: false
  end
end
