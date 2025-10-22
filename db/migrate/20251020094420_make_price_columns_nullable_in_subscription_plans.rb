class MakePriceColumnsNullableInSubscriptionPlans < ActiveRecord::Migration[7.0]
  def change
    change_column_null :subscription_plans, :monthly_price, true
    change_column_null :subscription_plans, :annual_price, true
  end
end
