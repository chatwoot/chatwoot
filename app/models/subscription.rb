class Subscription < ApplicationRecord
  include Events::Types

  belongs_to :account
  before_create :set_default_billing_params
  after_create :notify_creation

  enum state: [:trial, :active, :cancelled]

  def payment_source_added!
    self.payment_source_added = true
    self.save
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
    $dispatcher.dispatch(SUBSCRIPTION_CREATED, Time.zone.now, subscription: self)
  end
end
