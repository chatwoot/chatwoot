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

  private

  def default_plan
    Enterprise::Billing::PlanConfiguration.default_plan
  end
end
