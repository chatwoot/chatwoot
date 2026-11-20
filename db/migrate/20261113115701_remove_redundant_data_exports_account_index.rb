class RemoveRedundantDataExportsAccountIndex < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    # The (account_id, id) index also serves account-only lookups.
    remove_index :data_exports, :account_id, algorithm: :concurrently
  end
end
