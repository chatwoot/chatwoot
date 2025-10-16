module Enterprise::Api::V1::Accounts::CampaignsController
  include Enterprise::Concerns::SubscriptionCheck

  private

  def required_subscription_feature
    'campaigns' # Requires Premium tier
  end
end
