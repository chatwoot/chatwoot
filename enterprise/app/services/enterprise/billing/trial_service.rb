# Starts a card-backed trial by moving the account's $0 default-plan subscription onto a paid
# price with a trial_end, so the account keeps a single subscription and Stripe marks it trialing.
class Enterprise::Billing::TrialService
  include BillingHelper

  class Error < StandardError; end

  ENABLED_CONFIG = 'CHATWOOT_CLOUD_TRIAL_ENABLED'.freeze
  TRIAL_DAYS = 15
  MAX_SEATS = 50
  PRICE_CACHE_TTL = 1.hour

  pattr_initialize [:account!]

  # Plans are listed with prices even when the account can't start a trial, so a running trial can show what it will cost.
  def options
    {
      trial_days: TRIAL_DAYS,
      eligible: eligible?,
      seats: { default: [min_seats, Enterprise::Billing::CreateStripeCustomerService::DEFAULT_QUANTITY].max, min: min_seats, max: MAX_SEATS },
      plans: trial_plans.map { |plan| { name: plan['name'] }.merge(price_details(plan)) }
    }
  end

  def create_checkout_session(plan_name:, seats:)
    raise Error, I18n.t('errors.billing.trial.not_eligible') unless eligible?
    raise Error, I18n.t('errors.billing.trial.invalid_seats', min: min_seats, max: MAX_SEATS) unless seats.between?(min_seats, MAX_SEATS)

    plan = find_trial_plan!(plan_name)
    Stripe::Checkout::Session.create(
      mode: 'setup',
      customer: stripe_customer_id,
      currency: account.billing_currency,
      success_url: "#{billing_url}?trial_session_id={CHECKOUT_SESSION_ID}",
      cancel_url: billing_url,
      metadata: { plan_name: plan['name'], seats: seats },
      custom_text: { submit: { message: checkout_message(plan, seats) } }
    ).url
  end

  def start_trial(session_id:)
    session = completed_checkout_session!(session_id)
    plan = find_trial_plan!(session.metadata['plan_name'])
    account.with_lock do
      raise Error, I18n.t('errors.billing.trial.not_eligible') unless eligible?

      update_subscription_to_trial(plan, session.metadata['seats'].to_i, session.setup_intent.payment_method)
      account.update!(custom_attributes: account.custom_attributes.merge('trial_started_at' => Time.current))
    end
  end

  private

  def eligible?
    GlobalConfigService.load(ENABLED_CONFIG, 'false').to_s == 'true' &&
      account.billing_provider == Account::DEFAULT_BILLING_PROVIDER &&
      stripe_customer_id.present? &&
      default_plan?(account) &&
      account.custom_attributes['trial_started_at'].blank?
  end

  def completed_checkout_session!(session_id)
    session = Stripe::Checkout::Session.retrieve({ id: session_id, expand: ['setup_intent'] })
    return session if session.customer == stripe_customer_id && session.status == 'complete'

    raise Error, I18n.t('errors.billing.trial.invalid_session')
  end

  # Setup-mode Checkout only says "save payment information", so restate the trial terms at the button.
  def checkout_message(plan, seats)
    price = price_details(plan)
    I18n.t('billing_trial.checkout_message', days: TRIAL_DAYS, plan: plan['name'], amount: number_to_rounded(price[:amount] * seats),
                                             currency: price[:currency].upcase, interval: price[:interval], seats: seats,
                                             date: I18n.l(TRIAL_DAYS.days.from_now.to_date, format: :long))
  end

  def number_to_rounded(value)
    ActiveSupport::NumberHelper.number_to_rounded(value, precision: 2, strip_insignificant_zeros: true)
  end

  def update_subscription_to_trial(plan, seats, payment_method)
    subscription = default_plan_subscription
    item = subscription['items']['data'].first

    Stripe::Subscription.update(
      subscription.id,
      items: [{ id: item.id, price: price_id(plan), quantity: seats }],
      trial_end: TRIAL_DAYS.days.from_now.to_i,
      proration_behavior: 'none',
      default_payment_method: payment_method
    )
  end

  def default_plan_subscription
    Stripe::Subscription.list(customer: stripe_customer_id, status: 'active', limit: 1).data.first ||
      raise(Error, I18n.t('errors.billing.trial.not_eligible'))
  end

  # The trial has to fit the team that already exists, or the agent limit would lock members out.
  def min_seats
    [account.account_users.count, 1].max
  end

  def price_details(plan)
    Rails.cache.fetch("billing_trial/price/#{price_id(plan)}", expires_in: PRICE_CACHE_TTL) do
      price = Stripe::Price.retrieve(price_id(plan))
      { amount: price.unit_amount && (price.unit_amount / 100.0), currency: price.currency, interval: price.recurring&.interval }
    end
  end

  def price_id(plan)
    Enterprise::Billing::PlanConfiguration.price_id_for(plan, account.billing_currency)
  end

  # The first configured plan is the free default; every other plan can be trialed.
  def trial_plans
    Enterprise::Billing::PlanConfiguration.plans.drop(1)
  end

  def find_trial_plan!(plan_name)
    trial_plans.find { |plan| plan['name'].casecmp?(plan_name.to_s) } || raise(Error, I18n.t('errors.billing.trial.invalid_plan'))
  end

  def billing_url
    "#{ENV.fetch('FRONTEND_URL')}/app/accounts/#{account.id}/settings/billing"
  end

  def stripe_customer_id
    account.custom_attributes['stripe_customer_id']
  end
end
