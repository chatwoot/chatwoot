class AddCrmFieldsToAccountUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :account_users, :crm_external_id, :string
    add_column :account_users, :crm_synced_at, :datetime
    add_index :account_users, [:account_id, :crm_external_id], name: 'index_account_users_on_account_and_crm_external_id'
  end
end
