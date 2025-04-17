class AddPaymentDetailsToSubscriptionTopups < ActiveRecord::Migration[7.0]
  def change
    add_column :subscription_topups, :payment_details, :text
  end
end
