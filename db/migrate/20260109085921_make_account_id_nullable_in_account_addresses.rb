class MakeAccountIdNullableInAccountAddresses < ActiveRecord::Migration[7.1]
  def up
    change_column_null :account_addresses, :account_id, true
  end

  def down
    # Set account_id from addressable_id for Account type before making it NOT NULL
    execute <<-SQL.squish
      UPDATE account_addresses
      SET account_id = addressable_id
      WHERE addressable_type = 'Account' AND account_id IS NULL
    SQL

    change_column_null :account_addresses, :account_id, false
  end
end
