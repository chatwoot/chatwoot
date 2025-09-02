class Subscription < ApplicationRecord
  belongs_to :account

  PROVIDERS = %w[stripe paypal].freeze
  STATUSES = %w[active canceled past_due trial trialing incomplete_expired unpaid].freeze
  PLAN_KEYS = %w[basic pro premium app custom].freeze

  validates :external_id, presence: true, uniqueness: true
  validates :provider, inclusion: { in: PROVIDERS }
  validates :status, inclusion: { in: STATUSES }
  validates :plan_key, inclusion: { in: PLAN_KEYS }
  validates :account_id, presence: true

  scope :active, -> { where(status: 'active') }
  scope :trial, -> { where(status: ['trial', 'trialing']) }
  scope :stripe_subscriptions, -> { where(provider: 'stripe') }
  scope :paypal_subscriptions, -> { where(provider: 'paypal') }

  def active?
    status == 'active'
  end

  def trial?
    %w[trial trialing].include?(status)
  end

  def canceled?
    status == 'canceled'
  end

  def past_due?
    status == 'past_due'
  end

  def trial_expired?
    trial_end && trial_end < Time.current
  end

  def current_period_active?
    current_period_start && current_period_end &&
      Time.current.between?(current_period_start, current_period_end)
  end

  def days_until_trial_end
    return 0 unless trial_end

    ((trial_end - Time.current) / 1.day).ceil
  end

  def renews_on
    current_period_end
  end
end