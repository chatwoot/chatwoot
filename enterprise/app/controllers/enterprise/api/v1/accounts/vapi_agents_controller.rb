module Enterprise::Api::V1::Accounts::VapiAgentsController
  include Enterprise::Concerns::SubscriptionCheck

  private

  def required_subscription_feature
    'voice_agents' # Requires Premium tier
  end
end
