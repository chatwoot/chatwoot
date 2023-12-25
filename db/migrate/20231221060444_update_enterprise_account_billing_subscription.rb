class UpdateEnterpriseAccountBillingSubscription < ActiveRecord::Migration[7.0]
  def change
    rename_column :ee_account_billing_subscriptions, :subscription_stripe_id, :stripe_subscription_id
    rename_column :ee_account_billing_subscriptions, :customer_id, :stripe_customer_id
    add_column :ee_account_billing_subscriptions, :stripe_price_id, :string
    add_column :ee_account_billing_subscriptions, :stripe_product_id, :string
    add_column :ee_account_billing_subscriptions, :plan_name, :string
    remove_column :ee_account_billing_subscriptions, :billing_product_price_id, :integer
    remove_column :ee_account_billing_subscriptions, :partner, :string
  end
end
