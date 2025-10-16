class VapiAgentPolicy < ApplicationPolicy
  include SubscriptionPolicy

  def index?
    return true if @user.is_a?(SuperAdmin)

    # Require 'voice_agents' subscription feature (Premium tier only)
    require_subscription_feature_with_ownership('voice_agents')
  end

  def show?
    return true if @user.is_a?(SuperAdmin)

    require_subscription_feature_with_ownership('voice_agents')
  end

  def create?
    return true if @user.is_a?(SuperAdmin)

    require_subscription_feature_with_ownership('voice_agents')
  end

  def update?
    return true if @user.is_a?(SuperAdmin)

    require_subscription_feature_with_ownership('voice_agents')
  end

  def destroy?
    return true if @user.is_a?(SuperAdmin)

    require_subscription_feature_with_ownership('voice_agents')
  end

  def sync_agents?
    return true if @user.is_a?(SuperAdmin)

    require_subscription_feature_with_ownership('voice_agents')
  end
end
