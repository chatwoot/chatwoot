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

    updated = Stripe::Subscription.update(
      subscription.id, items: [{ id: subscription.items.data.first.id, quantity: quantity }], proration_behavior: 'none'
    )
    account.update!(custom_attributes: account.custom_attributes.merge('subscribed_quantity' => updated['quantity']))
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

  # Stripe sends trial_will_end three days before a trial ends. A cancelled plan won't start, so it gets the no-plan copy.
  # The plan is read from the event, since the subscription.updated that switched it may not have landed yet.
  def notify_ending(trialing_subscription)
    plan_name = Enterprise::Billing::PlanConfiguration.find_plan_by_product_id(trialing_subscription['plan']['product'])&.dig('name')
    cancelled = trialing_subscription['cancel_at'].present? || trialing_subscription['cancel_at_period_end']
    meta = {
      'account_name' => account.name,
      'trial_ends_on' => Time.zone.at(trialing_subscription['trial_end']).strftime('%B %d, %Y'),
      'has_plan' => plan_name.present? && plan_name != default_plan['name'] && !cancelled,
      'plan_name' => plan_name,
      'free_plan_name' => default_plan['name']
    }
    claim_ending_notice(trialing_subscription['trial_end']) do
      AdministratorNotifications::AccountNotificationMailer.with(account: account).trial_ending(meta).deliver_later
    end
  end

  private

  def default_plan
    Enterprise::Billing::PlanConfiguration.default_plan
  end

  # Stripe can deliver an event more than once, so one reminder is sent per trial end date. Enqueueing inside the lock
  # rolls the marker back if it fails, so Stripe's retry still sends the reminder.
  def claim_ending_notice(trial_end)
    account.with_lock do
      next if account.custom_attributes['trial_ending_notified_for'] == trial_end

      account.update!(custom_attributes: account.custom_attributes.merge('trial_ending_notified_for' => trial_end))
      yield
    end
  end

  # The stored state lags the portal by a webhook, so the live subscription must still be the free plan's trial too.
  def ensure_trial_without_card!
    live_free_trial = account.cloud_trial_state == 'no_card' && subscription['status'] == 'trialing' &&
                      Enterprise::Billing::PlanConfiguration.plan_contains_product_id?(default_plan, subscription['plan']['product'])
    raise Error, I18n.t('errors.billing.trial.not_eligible') unless live_free_trial
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
