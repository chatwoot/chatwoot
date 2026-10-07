class AddAccountCreatedAtIndexToCalls < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :calls, [:account_id, :created_at], algorithm: :concurrently
  end
end
