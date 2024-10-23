class ChangeFeatureFlagsToBigintInAccounts < ActiveRecord::Migration[7.0]
  def up
    change_column :accounts, :feature_flags, :bigint
  end

  def down
    change_column :accounts, :feature_flags, :integer
  end
end
