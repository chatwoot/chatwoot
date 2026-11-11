module Enterprise::Api::V1::Accounts::FilterRecommendationsController
  include BillingHelper

  private

  # Paid means a Cloud account outside the default plan, or a self-hosted install outside the community plan.
  def recommendations_available?
    return !default_plan?(Current.account) if ChatwootApp.chatwoot_cloud?

    ChatwootHub.pricing_plan != 'community'
  end
end
