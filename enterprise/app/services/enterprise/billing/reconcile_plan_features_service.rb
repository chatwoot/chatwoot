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

  BUSINESS_PLAN_FEATURES = %w[sla custom_roles csat_review_notes conversation_required_attributes advanced_assignment custom_tools].freeze
  ENTERPRISE_PLAN_FEATURES = %w[audit_logs disable_branding saml].freeze
  PREMIUM_PLAN_FEATURES = (STARTUP_PLAN_FEATURES + BUSINESS_PLAN_FEATURES + ENTERPRISE_PLAN_FEATURES).freeze

  pattr_initialize [:account!]

  def perform
    account.disable_features(*PREMIUM_PLAN_FEATURES)
    account.enable_features(*current_plan_features)
    account.enable_features(*manually_managed_features)
    account.save!
  end

  private

  def current_plan_features
    return [] if default_plan?

    case account.custom_attributes['plan_name']
    when 'Startups' then STARTUP_PLAN_FEATURES
    when 'Business' then STARTUP_PLAN_FEATURES + BUSINESS_PLAN_FEATURES
    when 'Enterprise' then PREMIUM_PLAN_FEATURES
    else []
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

  def manually_managed_features
    @manually_managed_features ||= Internal::Accounts::InternalAttributesService.new(account).manually_managed_features
  end
end
