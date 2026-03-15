class AddHubFieldsToUsersContactsAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :hub_id, :string, limit: 36
    add_column :users, :hub_synced_at, :datetime
    add_index :users, :hub_id, unique: true

    add_column :contacts, :hub_id, :string, limit: 36
    add_column :contacts, :hub_synced_at, :datetime
    add_index :contacts, [:hub_id, :account_id], unique: true

    add_column :accounts, :hub_id, :string, limit: 36
    add_column :accounts, :hub_synced_at, :datetime
    add_column :accounts, :hub_client_slug, :string, limit: 100
    add_index :accounts, :hub_id, unique: true
    add_index :accounts, :hub_client_slug, unique: true
  end
end
