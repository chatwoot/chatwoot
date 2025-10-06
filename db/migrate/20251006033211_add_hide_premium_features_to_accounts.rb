class AddHidePremiumFeaturesToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :hide_premium_features, :boolean, default: false, null: false
  end
end
