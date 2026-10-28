class AddFeatureFlagsExt2ToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :feature_flags_ext_1, :bigint, default: 0, null: false
  end
end
