module Enterprise::CampaignPolicy
  include Enterprise::Concerns::SubscriptionPolicy

  def index?
    # Require 'campaigns' subscription feature (Premium tier only)
    require_subscription_feature('campaigns')
  end

  def show?
    require_subscription_feature('campaigns')
  end

  def create?
    require_subscription_feature('campaigns')
  end

  def update?
    require_subscription_feature('campaigns')
  end

  def destroy?
    require_subscription_feature('campaigns')
  end
end
