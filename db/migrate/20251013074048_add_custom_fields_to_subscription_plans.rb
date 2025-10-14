class AddCustomFieldsToSubscriptionPlans < ActiveRecord::Migration[7.0]
  def change
    add_column :subscription_plans, :is_custom, :boolean, default: false
    add_reference :subscription_plans, :owner_account, foreign_key: { to_table: :accounts }
  end
end