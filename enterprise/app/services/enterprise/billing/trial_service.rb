# Starts a card-backed trial by moving the account's $0 default-plan subscription onto a paid
# price with a trial_end, so the account keeps a single subscription and Stripe marks it trialing.
class Enterprise::Billing::TrialService
  include BillingHelper

  class Error < StandardError; end

  FEATURE_FLAG = 'billing_trial'.freeze
  TRIAL_DAYS = 15

  pattr_initialize [:account!]

  def available_plans
    eligible? ? trial_plans.pluck('name') : []
  end

  def create_checkout_session(plan_name:)
    raise Error, I18n.t('errors.billing.trial.not_eligible') unless eligible?

    plan = find_trial_plan!(plan_name)
    Stripe::Checkout::Session.create(
      mode: 'setup',
      customer: stripe_customer_id,
      currency: account.billing_currency,
      success_url: "#{billing_url}?trial_session_id={CHECKOUT_SESSION_ID}",
      cancel_url: billing_url,
      metadata: { plan_name: plan['name'] }
    ).url
  end

  def start_trial(session_id:)
    session = Stripe::Checkout::Session.retrieve({ id: session_id, expand: ['setup_intent'] })
    raise Error, I18n.t('errors.billing.trial.invalid_session') unless session.customer == stripe_customer_id && session.status == 'complete'

    plan = find_trial_plan!(session.metadata['plan_name'])
    account.with_lock do
      raise Error, I18n.t('errors.billing.trial.not_eligible') unless eligible?

      update_subscription_to_trial(plan, session.setup_intent.payment_method)
      account.update!(custom_attributes: account.custom_attributes.merge('trial_started_at' => Time.current))
    end
  end

  private

  def eligible?
    account.feature_enabled?(FEATURE_FLAG) &&
      account.billing_provider == Account::DEFAULT_BILLING_PROVIDER &&
      stripe_customer_id.present? &&
      default_plan?(account) &&
      account.custom_attributes['trial_started_at'].blank?
  end

  def update_subscription_to_trial(plan, payment_method)
    subscription = default_plan_subscription
    item = subscription['items']['data'].first

    Stripe::Subscription.update(
      subscription.id,
      items: [{ id: item.id, price: Enterprise::Billing::PlanConfiguration.price_id_for(plan, account.billing_currency), quantity: item.quantity }],
      trial_end: TRIAL_DAYS.days.from_now.to_i,
      proration_behavior: 'none',
      default_payment_method: payment_method
    )
  end

  def default_plan_subscription
    Stripe::Subscription.list(customer: stripe_customer_id, status: 'active', limit: 1).data.first ||
      raise(Error, I18n.t('errors.billing.trial.not_eligible'))
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
