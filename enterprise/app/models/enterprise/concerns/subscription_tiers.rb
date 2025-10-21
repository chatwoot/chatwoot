module Enterprise::Concerns::SubscriptionTiers
  extend ActiveSupport::Concern

  # Unlocking Tech Subscription Tiers
  # NOTE: This is separate from Chatwoot's Enterprise Edition licensing
  # These are YOUR subscription tiers that YOUR customers pay for
  SUBSCRIPTION_TIERS = {
    basic: {
      name: 'Basic',
      display_name: 'Basic (Free)',
      features: %w[
        conversations
        contacts
        inboxes
        labels
        teams
        canned_responses
        automation
        integrations
        webhooks
        basic_settings
      ]
    },
    professional: {
      name: 'Professional',
      display_name: 'Professional',
      features: %w[
        conversations
        contacts
        inboxes
        labels
        teams
        canned_responses
        automation
        integrations
        webhooks
        basic_settings
        reports
        advanced_reports
        custom_attributes
      ]
    },
    premium: {
      name: 'Premium',
      display_name: 'Premium',
      features: %w[
        conversations
        contacts
        inboxes
        labels
        teams
        canned_responses
        automation
        integrations
        webhooks
        basic_settings
        reports
        advanced_reports
        custom_attributes
        campaigns
        voice_agents
      ]
    }
  }.freeze

  def subscription_tier
    (custom_attributes['subscription_tier'] || 'basic').downcase.to_sym
  end

  def has_subscription_feature?(feature_name)
    return true if feature_name.blank?

    SUBSCRIPTION_TIERS.dig(subscription_tier, :features)&.include?(feature_name.to_s) || false
  end

  def subscription_display_name
    SUBSCRIPTION_TIERS.dig(subscription_tier, :display_name) || 'Basic (Free)'
  end

  def required_tier_for_feature(feature_name)
    SUBSCRIPTION_TIERS.each do |tier, config|
      return tier.to_s if config[:features].include?(feature_name.to_s)
    end
    'premium' # Default to highest tier if feature not found
  end

  def subscription_features
    SUBSCRIPTION_TIERS.dig(subscription_tier, :features) || SUBSCRIPTION_TIERS[:basic][:features]
  end
end
