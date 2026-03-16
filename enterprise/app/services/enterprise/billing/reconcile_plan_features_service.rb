class Enterprise::Billing::ReconcilePlanFeaturesService
  CLOUD_PLANS_CONFIG = 'CHATWOOT_CLOUD_PLANS'.freeze

  # Plan hierarchy: Hacker (default) -> Startups -> Business -> Enterprise
  # Each higher tier includes all features from the lower tiers
  STARTUP_PLAN_FEATURES = %w[
    inbound_emails
    help_center
    campaigns
    team_management
    channel_facebook
    channel_email
    channel_instagram
    captain_integration
    advanced_search_indexing
    advanced_search
    linear_integration
  ].freeze

  BUSINESS_PLAN_FEATURES = %w[sla custom_roles csat_review_notes conversation_required_attributes advanced_assignment].freeze
  ENTERPRISE_PLAN_FEATURES = %w[audit_logs disable_branding saml].freeze

  pattr_initialize [:account!]

  def perform
    default_plan? ? disable_all_premium_features : enable_features_for_current_plan
    enable_account_manually_managed_features
    account.save!
  end

  private

  def disable_all_premium_features
    account.disable_features(*STARTUP_PLAN_FEATURES)
    account.disable_features(*BUSINESS_PLAN_FEATURES)
    account.disable_features(*ENTERPRISE_PLAN_FEATURES)
  end

  def enable_features_for_current_plan
    # Reset the premium feature set first so downgrades don't leave stale flags behind.
    disable_all_premium_features

    case account.custom_attributes['plan_name']
    when 'Startups'
      account.enable_features(*STARTUP_PLAN_FEATURES)
    when 'Business'
      account.enable_features(*STARTUP_PLAN_FEATURES, *BUSINESS_PLAN_FEATURES)
    when 'Enterprise'
      account.enable_features(*STARTUP_PLAN_FEATURES, *BUSINESS_PLAN_FEATURES, *ENTERPRISE_PLAN_FEATURES)
    end
  end

  def default_plan?
    default_plan_name = cloud_plans.first&.dig('name')
    return false if default_plan_name.blank?

    plan_name = account.custom_attributes['plan_name']
    plan_name.blank? || plan_name == default_plan_name
  end

  def cloud_plans
    @cloud_plans ||= InstallationConfig.find_by(name: CLOUD_PLANS_CONFIG)&.value || []
  end

  def enable_account_manually_managed_features
    service = Internal::Accounts::InternalAttributesService.new(account)
    features = service.manually_managed_features

    account.enable_features(*features) if features.present?
  end
end
