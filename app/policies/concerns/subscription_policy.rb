module SubscriptionPolicy
  extend ActiveSupport::Concern

  # Check if the account has access to a specific subscription feature
  # This is separate from Chatwoot's Enterprise Edition features
  def has_subscription_feature?(feature_name)
    return false unless @user&.account

    @user.account.has_subscription_feature?(feature_name)
  end

  # Require both administrator role AND subscription feature access
  def require_subscription_feature(feature_name)
    @account_user&.administrator? && has_subscription_feature?(feature_name)
  end

  # Require owner/admin role AND subscription feature access
  def require_subscription_feature_with_ownership(feature_name)
    (@account_user&.administrator? || @account_user&.owner?) &&
      has_subscription_feature?(feature_name)
  end

  # Get the current subscription tier
  def current_subscription_tier
    return 'basic' unless @user&.account

    @user.account.subscription_tier.to_s
  end

  # Get required tier for a feature
  def required_tier_for(feature_name)
    return 'premium' unless @user&.account

    @user.account.required_tier_for_feature(feature_name)
  end
end
