# New Stripe-billed cloud accounts start a 15-day trial at signup without a card, on the free default plan.
# Seats change through the API during that trial, since the portal asks for a card on any paid change.
# Picking a paid plan in the billing portal collects the card and keeps the trial end date, because the
# portal's trial_update_behavior is continue_trial; the first charge then happens when the trial ends.
class Enterprise::Billing::TrialService
  class Error < StandardError; end

  ENABLED_CONFIG = 'CHATWOOT_CLOUD_TRIAL_ENABLED'.freeze
  TRIAL_DAYS = 15
  MAX_SEATS = 25

  pattr_initialize [:account!]

  def self.enabled?
    ChatwootApp.chatwoot_cloud? && GlobalConfigService.load(ENABLED_CONFIG, 'false').to_s == 'true'
  end

  def portal_url
    ensure_trial_without_card!

    Stripe::BillingPortal::Session.create(
      customer: stripe_customer_id,
      return_url: billing_url,
      flow_data: {
        type: 'subscription_update',
        subscription_update: { subscription: subscription.id },
        after_completion: { type: 'redirect', redirect: { return_url: billing_url } }
      }
    ).url
  end

  def update_seats(quantity)
    ensure_trial_without_card!
    raise Error, I18n.t('errors.billing.trial.invalid_seats', max: MAX_SEATS) unless quantity.to_i.between?(1, MAX_SEATS)

    updated = Stripe::Subscription.update(
      subscription.id, items: [{ id: subscription.items.data.first.id, quantity: quantity.to_i }], proration_behavior: 'none'
    )
    account.update!(custom_attributes: account.custom_attributes.merge('subscribed_quantity' => updated['quantity']))
  end

  # Nothing is billed before a plan is chosen, but Stripe can't hold subscriptions in two currencies on one customer.
  # So the trial moves to a new customer in the chosen currency, with the same end date and seats.
  def switch_currency(currency)
    ensure_trial_without_card!
    currency = Enterprise::Billing::Currencies.normalize(currency)
    unless account.trial_currency_options.include?(currency) && currency != account.billing_currency
      raise Error, I18n.t('errors.billing.invalid_currency')
    end

    old_customer_id = stripe_customer_id
    trial = subscription
    ActiveRecord::Base.transaction do
      account.update!(custom_attributes: account.custom_attributes.except('stripe_customer_id').merge('billing_currency' => currency))
      Enterprise::Billing::CreateStripeCustomerService.new(account: account, trial_end: trial.trial_end, quantity: trial.quantity).perform
    end
    Stripe::Customer.delete(old_customer_id)
  end

  # Seats added during a trial without a card go back to the free plan's seats once it ends.
  def reset_seats(ended_subscription)
    return unless account.cloud_trial_state == 'ended'

    free_seats = default_plan['default_quantity'] || Enterprise::Billing::CreateStripeCustomerService::DEFAULT_QUANTITY
    return if ended_subscription['quantity'] <= free_seats

    Stripe::Subscription.update(
      ended_subscription.id, items: [{ id: ended_subscription['items']['data'].first['id'], quantity: free_seats }], proration_behavior: 'none'
    )
  end

  # Stripe sends trial_will_end three days before a trial ends.
  def notify_ending(trialing_subscription)
    plan_name = account.custom_attributes['plan_name']
    meta = {
      'account_name' => account.name,
      'trial_ends_on' => Time.zone.at(trialing_subscription['trial_end']).strftime('%B %d, %Y'),
      'has_plan' => plan_name != default_plan['name'],
      'plan_name' => plan_name,
      'free_plan_name' => default_plan['name']
    }
    AdministratorNotifications::AccountNotificationMailer.with(account: account).trial_ending(meta).deliver_later
  end

  private

  def default_plan
    Enterprise::Billing::PlanConfiguration.default_plan
  end

  def ensure_trial_without_card!
    raise Error, I18n.t('errors.billing.trial.not_eligible') unless account.cloud_trial_state == 'no_card'
  end

  def subscription
    @subscription ||= Stripe::Subscription.list(customer: stripe_customer_id, limit: 1).data.first
  end

  def billing_url
    "#{ENV.fetch('FRONTEND_URL')}/app/accounts/#{account.id}/settings/billing"
  end

  def stripe_customer_id
    account.custom_attributes['stripe_customer_id']
  end
end
