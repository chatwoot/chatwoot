class AddAccountUserIdColumnToHook < ActiveRecord::Migration[7.0]
  def change
    add_column :integrations_hooks, :account_user_id, :integer
    add_foreign_key :integrations_hooks, :account_users, column: :account_user_id
  end
end
