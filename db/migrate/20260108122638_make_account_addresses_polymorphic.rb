class MakeAccountAddressesPolymorphic < ActiveRecord::Migration[7.1]
  def up
    # Add polymorphic columns
    add_column :account_addresses, :addressable_type, :string
    add_column :account_addresses, :addressable_id, :bigint

    # Migrate existing data: all current addresses belong to Account
    execute <<-SQL.squish
      UPDATE account_addresses
      SET addressable_type = 'Account',
          addressable_id = account_id
      WHERE account_id IS NOT NULL
    SQL

    # Add composite index for efficient polymorphic lookups
    add_index :account_addresses, [:addressable_type, :addressable_id], name: 'index_account_addresses_on_addressable'

    # Make columns NOT NULL after migrating data
    change_column_null :account_addresses, :addressable_type, false
    change_column_null :account_addresses, :addressable_id, false

    # Keep account_id temporarily for safe rollback
    # In a future migration (after production verification), we can remove it:
    # remove_column :account_addresses, :account_id
  end

  def down
    # Restore account_id if it was removed
    unless column_exists?(:account_addresses, :account_id)
      add_reference :account_addresses, :account, foreign_key: true

      # Restore data only for Account type
      execute <<-SQL.squish
        UPDATE account_addresses
        SET account_id = addressable_id
        WHERE addressable_type = 'Account'
      SQL
    end

    remove_index :account_addresses, name: 'index_account_addresses_on_addressable'
    remove_column :account_addresses, :addressable_type
    remove_column :account_addresses, :addressable_id
  end
end
