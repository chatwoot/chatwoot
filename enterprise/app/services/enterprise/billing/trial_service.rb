# New Stripe-billed cloud accounts start a 15-day trial at signup without a card, on the free default plan.
class Enterprise::Billing::TrialService
  ENABLED_CONFIG = 'CHATWOOT_CLOUD_TRIAL_ENABLED'.freeze
  TRIAL_DAYS = 15

  pattr_initialize [:account!]

  def self.enabled?
    ChatwootApp.chatwoot_cloud? && GlobalConfigService.load(ENABLED_CONFIG, 'false').to_s == 'true'
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
  def notify_ending(trialing_subscription)
    return unless claim_ending_notice(trialing_subscription['trial_end'])

    plan_name = account.custom_attributes['plan_name']
    cancelled = trialing_subscription['cancel_at'].present? || trialing_subscription['cancel_at_period_end']
    meta = {
      'account_name' => account.name,
      'trial_ends_on' => Time.zone.at(trialing_subscription['trial_end']).strftime('%B %d, %Y'),
      'has_plan' => plan_name != default_plan['name'] && !cancelled,
      'plan_name' => plan_name,
      'free_plan_name' => default_plan['name']
    }
    AdministratorNotifications::AccountNotificationMailer.with(account: account).trial_ending(meta).deliver_later
  end

  private

  def default_plan
    Enterprise::Billing::PlanConfiguration.default_plan
  end

  # Stripe can deliver an event more than once, so one reminder is sent per trial end date.
  def claim_ending_notice(trial_end)
    account.with_lock do
      next false if account.custom_attributes['trial_ending_notified_for'] == trial_end

      account.update!(custom_attributes: account.custom_attributes.merge('trial_ending_notified_for' => trial_end))
    end
  end
end
