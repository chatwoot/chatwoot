module Enterprise::Concerns::SubscriptionCheck
  extend ActiveSupport::Concern

  included do
    # Skip subscription check for super admins
    before_action :check_subscription_access, unless: -> { current_user.is_a?(SuperAdmin) }
  end

  private

  def check_subscription_access
    return true unless respond_to?(:required_subscription_feature, true)

    feature = required_subscription_feature

    return true if feature.blank?
    return true if current_account.has_subscription_feature?(feature)

    render_subscription_error(feature)
  end

  def render_subscription_error(feature)
    required_tier = current_account.required_tier_for_feature(feature)
    current_tier = current_account.subscription_tier

    render json: {
      error: 'Subscription upgrade required',
      message: "This feature requires #{required_tier.capitalize} subscription",
      feature: feature,
      current_tier: current_tier,
      required_tier: required_tier,
      upgrade_url: subscription_upgrade_path(feature: feature)
    }, status: :payment_required # 402
  end

  def subscription_upgrade_path(params = {})
    # TODO: Update with your actual upgrade URL
    "/app/accounts/#{current_account.id}/billing/upgrade?#{params.to_query}"
  end
end
