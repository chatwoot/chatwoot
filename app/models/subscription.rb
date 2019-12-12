# == Schema Information
#
# Table name: subscriptions
#
#  id                   :integer          not null, primary key
#  billing_plan         :string           default("trial")
#  expiry               :datetime
#  payment_source_added :boolean          default(FALSE)
#  pricing_version      :string
#  state                :integer          default("trial")
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  account_id           :integer
#  stripe_customer_id   :string
#

class Subscription < ApplicationRecord
  include Events::Types

  belongs_to :account
  before_create :set_default_billing_params
  after_create :notify_creation

  enum state: [:trial, :active, :cancelled]

  def payment_source_added!
    self.payment_source_added = true
    save
  end

  def trial_expired?
    (trial? && expiry < Date.current) ||
      (cancelled? && !payment_source_added)
  end

  def suspended?
    cancelled? && payment_source_added
  end

  def summary
    {
      state: state,
      expiry: expiry.to_i
    }
  end

  private

  def set_default_billing_params
    self.expiry = Time.now + Plan.default_trial_period
    self.pricing_version = Plan.default_pricing_version
  end

  def notify_creation
    Rails.configuration.dispatcher.dispatch(SUBSCRIPTION_CREATED, Time.zone.now, subscription: self)
  end
end
