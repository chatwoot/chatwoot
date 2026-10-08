# New Stripe-billed cloud accounts start a 15-day trial at signup without a card, on the free default plan.
# Picking a paid plan in the billing portal collects the card and keeps the trial end date, because the
# portal's trial_update_behavior is continue_trial; the first charge then happens when the trial ends.
class Enterprise::Billing::TrialService
  class Error < StandardError; end

  ENABLED_CONFIG = 'CHATWOOT_CLOUD_TRIAL_ENABLED'.freeze
  TRIAL_DAYS = 15

  pattr_initialize [:account!]

  def self.enabled?
    ChatwootApp.chatwoot_cloud? && GlobalConfigService.load(ENABLED_CONFIG, 'false').to_s == 'true'
  end

  def portal_url
    raise Error, I18n.t('errors.billing.trial.not_eligible') unless account.cloud_trial_state == 'no_card'

    Stripe::BillingPortal::Session.create(
      customer: stripe_customer_id,
      return_url: billing_url,
      flow_data: {
        type: 'subscription_update',
        subscription_update: { subscription: Stripe::Subscription.list(customer: stripe_customer_id, limit: 1).data.first.id },
        after_completion: { type: 'redirect', redirect: { return_url: billing_url } }
      }
    ).url
  end

  private

  def billing_url
    "#{ENV.fetch('FRONTEND_URL')}/app/accounts/#{account.id}/settings/billing"
  end

  def stripe_customer_id
    account.custom_attributes['stripe_customer_id']
  end
end
