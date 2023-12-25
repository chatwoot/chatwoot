# == Schema Information
#
# Table name: ee_billing_product_prices
#
#  id                 :bigint           not null, primary key
#  active             :boolean          default(FALSE)
#  features           :integer          default(0), not null
#  limits             :jsonb            not null
#  stripe_nickname    :string
#  unit_amount        :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  billing_product_id :bigint
#  price_stripe_id    :string
#
# Indexes
#
#  index_ee_billing_product_prices_on_billing_product_id  (billing_product_id)
#  index_ee_billing_product_prices_on_price_stripe_id     (price_stripe_id) UNIQUE
#
class Enterprise::BillingProductPrice < ApplicationRecord
  belongs_to :billing_product, class_name: 'Enterprise::BillingProduct'

  # after_save :update_limits_job

  def amount
    unit_amount
  end

  def limits=(value)
    self[:limits] = value.is_a?(String) ? JSON.parse(value) : value
  end

  def update_limits_job
    Account::UpdateAccountsLimitsJob.perform_later(id)
  end

  def update_accounts_limits
    enterprise_account_billing_subscriptions.each do |billing_subscriptions|
      billing_subscriptions.account.set_limits_for_account(self)
    end
  end
end
