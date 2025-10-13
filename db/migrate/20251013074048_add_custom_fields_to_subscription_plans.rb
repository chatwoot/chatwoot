class AddCustomFieldsToSubscriptionPlans < ActiveRecord::Migration[7.0]
  def change
    add_column :subscription_plans, :is_custom, :boolean
    add_reference :subscription_plans, :owner_account_id, { to_table: :accounts }
  end
end
