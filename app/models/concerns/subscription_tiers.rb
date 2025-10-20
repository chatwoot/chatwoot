module SubscriptionTiers
  extend ActiveSupport::Concern

  # Subscription Tiers for feature gating
  # NOTE: This is separate from Chatwoot's Enterprise Edition licensing
  # These are YOUR subscription tiers that YOUR customers pay for
  SUBSCRIPTION_TIERS = {
    basic: {
      name: 'Basic',
      display_name: 'Basic (Free)',
      stripe_price_id: nil,
      price: 0,
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
      stripe_price_id: 'price_1SJFZADAergAr76jPimoHbnS',
      price: 29,
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
      stripe_price_id: 'price_1SJFcwDAergAr76jLuE2WgmT',
      price: 99,
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

  def stripe_price_id_for_tier(tier)
    SUBSCRIPTION_TIERS.dig(tier.to_sym, :stripe_price_id)
  end

  def price_for_tier(tier)
    SUBSCRIPTION_TIERS.dig(tier.to_sym, :price) || 0
  end
end
