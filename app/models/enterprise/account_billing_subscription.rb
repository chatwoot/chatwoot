#== Schema Information
#
# Table name: ee_account_billing_subscriptions
#
#  id                       :bigint           not null, primary key
#  cancelled_at             :datetime
#  current_period_end       :datetime
#  status                   :string           default("true"), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  account_id               :bigint           not null
#  billing_product_price_id :bigint           not null
#  subscription_stripe_id   :string
#
# Indexes
#
#  billing_product_price_index                           (billing_product_price_id)
#  index_ee_account_billing_subscriptions_on_account_id  (account_id)
#  subscription_stripe_id_index                          (subscription_stripe_id) UNIQUE
#
class Enterprise::AccountBillingSubscription < ApplicationRecord
  belongs_to :billing_product_price, class_name: '::Enterprise::BillingProductPrice'
  belongs_to :account, class_name: '::Account'
  after_save :update_account_limits

  def update_account_limits
    account.set_limits_for_account(billing_product_price)
  end
end
