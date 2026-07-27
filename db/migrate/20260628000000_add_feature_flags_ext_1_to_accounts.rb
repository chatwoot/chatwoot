class AddFeatureFlagsExt1ToAccounts < ActiveRecord::Migration[7.0]
  def change
    # Must run before migrations that call FlagShihTzu on ext_1 features
    # (e.g. 20260629 unread_count_for_filters). Idempotent for envs that
    # already applied the old 20260706* timestamp.
    return if column_exists?(:accounts, :feature_flags_ext_1)

    add_column :accounts, :feature_flags_ext_1, :bigint, default: 0, null: false
  end
end
