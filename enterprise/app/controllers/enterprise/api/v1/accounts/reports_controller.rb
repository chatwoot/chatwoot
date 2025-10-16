module Enterprise::Api::V1::Accounts::ReportsController
  include Enterprise::Concerns::SubscriptionCheck

  private

  def required_subscription_feature
    'reports' # Requires Professional tier
  end
end
