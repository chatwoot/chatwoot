class RemoveCancelledAtFromEeAccountBillingSubscriptions < ActiveRecord::Migration[7.0]
  def change
    remove_column :ee_account_billing_subscriptions, :cancelled_at
    add_column :ee_account_billing_subscriptions, :subscription_status, :string
  end
end
