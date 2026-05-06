class AddAccountOwnerToContactsAndCompanies < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    add_column :contacts, :account_owner_id, :integer
    add_column :companies, :account_owner_id, :integer

    add_index :contacts, :account_owner_id, algorithm: :concurrently
    add_index :companies, :account_owner_id, algorithm: :concurrently

    add_foreign_key :contacts, :users, column: :account_owner_id, on_delete: :nullify, validate: false
    add_foreign_key :companies, :users, column: :account_owner_id, on_delete: :nullify, validate: false

    validate_foreign_key :contacts, :users, column: :account_owner_id
    validate_foreign_key :companies, :users, column: :account_owner_id
  end

  def down
    remove_foreign_key :contacts, column: :account_owner_id
    remove_foreign_key :companies, column: :account_owner_id

    remove_index :contacts, :account_owner_id, algorithm: :concurrently
    remove_index :companies, :account_owner_id, algorithm: :concurrently

    remove_column :contacts, :account_owner_id
    remove_column :companies, :account_owner_id
  end
end
