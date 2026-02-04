class AddFeatureFlags2ToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :feature_flags_2, :bigint, default: 0, null: false
  end
end
