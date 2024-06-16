class AddPermissionsToAccountUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :account_users, :permissions, :jsonb, default: {}
  end
end
