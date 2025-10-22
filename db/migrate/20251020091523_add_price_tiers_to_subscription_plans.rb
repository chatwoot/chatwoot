class AddPriceTiersToSubscriptionPlans < ActiveRecord::Migration[7.0]
  def change
    add_column :subscription_plans, :quarterly_price, :numeric, precision: 16, scale: 2, null: true
    add_column :subscription_plans, :semi_annual_price, :numeric, precision: 16, scale: 2, null: true
  end
end
