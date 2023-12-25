# == Schema Information
#
# Table name: ee_account_billing_subscriptions
#
#  id                     :bigint           not null, primary key
#  current_period_end     :datetime
#  plan_name              :string
#  status                 :string           default("true"), not null
#  subscription_status    :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :bigint           not null
#  stripe_customer_id     :string
#  stripe_price_id        :string
#  stripe_product_id      :string
#  stripe_subscription_id :string
#
# Indexes
#
#  index_ee_account_billing_subscriptions_on_account_id  (account_id)
#  subscription_stripe_id_index                          (stripe_subscription_id) UNIQUE
#
class Enterprise::AccountBillingSubscription < ApplicationRecord
  belongs_to :account, class_name: '::Account'
  # after_save :update_account_limits

  # def update_account_limits
  #   account.set_limits_for_account(billing_product_price)
  # end
end
