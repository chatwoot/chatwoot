class RemovePeriodScopedColumnsFromAddons < ActiveRecord::Migration[7.1]
  # The Addon is now a catalog of available add-on packages only. Account-scoped
  # activation (account, base package and the add-on's own period) moves to the
  # new `account_addons` table, so those columns are dropped here.
  #
  # The table is brand-new (no production data), so the loss of the account /
  # package / period linkage on existing rows is accepted.
  def up
    remove_index :addons, :account_id
    remove_index :addons, :package_id
    remove_index :addons, [:account_id, :ends_at]
    remove_column :addons, :account_id
    remove_column :addons, :package_id
    remove_column :addons, :starts_at
    remove_column :addons, :ends_at
  end

  def down
    add_column :addons, :account_id, :bigint
    add_column :addons, :package_id, :bigint
    add_column :addons, :starts_at, :datetime
    add_column :addons, :ends_at, :datetime
    add_index :addons, :account_id
    add_index :addons, :package_id
    add_index :addons, [:account_id, :ends_at]
  end
end
