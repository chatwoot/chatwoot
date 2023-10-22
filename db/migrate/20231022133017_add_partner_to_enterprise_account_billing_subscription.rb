class AddPartnerToEnterpriseAccountBillingSubscription < ActiveRecord::Migration[7.0]
  def change
    add_column :ee_account_billing_subscriptions, :partner, :string
  end
end
