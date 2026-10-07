# Starts a card-backed trial on the account's $0 default-plan subscription and hands the customer to a
# Stripe billing portal flow to pick the paid plan. Plans, prices and seats live in the default portal
# configuration, whose trial_update_behavior must be continue_trial so the trial carries over to the chosen plan.
class Enterprise::Billing::TrialService
  include BillingHelper

  class Error < StandardError; end

  ENABLED_CONFIG = 'CHATWOOT_CLOUD_TRIAL_ENABLED'.freeze
  TRIAL_DAYS = 15

  pattr_initialize [:account!]

  def options
    { trial_days: TRIAL_DAYS, eligible: eligible? }
  end

  def portal_url
    account.with_lock do
      raise Error, I18n.t('errors.billing.trial.not_eligible') unless eligible?

      # Returning from an abandoned portal visit reopens it on the trial that is already running.
      start_trial(default_plan_subscription) if account.custom_attributes['trial_started_at'].blank?
    end
    create_portal_session.url
  end

  private

  # A trial that was started but never moved to a paid plan is still running on the default plan.
  def eligible?
    GlobalConfigService.load(ENABLED_CONFIG, 'false').to_s == 'true' &&
      account.billing_provider == Account::DEFAULT_BILLING_PROVIDER &&
      stripe_customer_id.present? &&
      default_plan?(account) &&
      (account.custom_attributes['trial_started_at'].blank? || account.custom_attributes['subscription_status'] == 'trialing')
  end

  def start_trial(subscription)
    Stripe::Subscription.update(subscription.id, trial_end: TRIAL_DAYS.days.from_now.to_i, proration_behavior: 'none')
    account.update!(custom_attributes: account.custom_attributes.merge('trial_started_at' => Time.current))
  end

  def create_portal_session
    Stripe::BillingPortal::Session.create(
      customer: stripe_customer_id,
      return_url: billing_url,
      flow_data: {
        type: 'subscription_update',
        subscription_update: { subscription: default_plan_subscription.id },
        after_completion: { type: 'redirect', redirect: { return_url: billing_url } }
      }
    )
  end

  def default_plan_subscription
    @default_plan_subscription ||= Stripe::Subscription.list(customer: stripe_customer_id, limit: 1).data.first ||
                                   raise(Error, I18n.t('errors.billing.trial.not_eligible'))
  end

  def billing_url
    "#{ENV.fetch('FRONTEND_URL')}/app/accounts/#{account.id}/settings/billing"
  end

  def stripe_customer_id
    account.custom_attributes['stripe_customer_id']
  end
end
