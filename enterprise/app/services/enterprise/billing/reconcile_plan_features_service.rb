class Enterprise::Billing::ReconcilePlanFeaturesService
  CLOUD_PLANS_CONFIG = 'CHATWOOT_CLOUD_PLANS'.freeze
  SHOPIFY_MANAGED_FEATURES = 'shopify_managed_features'.freeze

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
    channel_tiktok
    captain_integration
    captain_document_auto_sync
    advanced_search_indexing
    advanced_search
    linear_integration
    channel_voice
    api_and_webhooks
    data_import
  ].freeze

  BUSINESS_PLAN_FEATURES = %w[
    sla
    custom_roles
    csat_review_notes
    conversation_required_attributes
    advanced_assignment
    custom_tools
    companies
  ].freeze
  ENTERPRISE_PLAN_FEATURES = %w[audit_logs disable_branding saml].freeze
  PREMIUM_PLAN_FEATURES = (STARTUP_PLAN_FEATURES + BUSINESS_PLAN_FEATURES + ENTERPRISE_PLAN_FEATURES).freeze
  SHOPIFY_BASE_MANAGED_FEATURES = (PREMIUM_PLAN_FEATURES + %w[captain_integration_v2]).freeze

  pattr_initialize [:account!]

  def perform
    return if shopify_billing? && !Shopify::FeatureGate.enabled?(account: account)

    account.disable_features(*managed_plan_features)
    account.disable_features('captain_integration_v2') if default_plan?
    account.enable_features(*current_plan_features)
    account.enable_features('captain_integration_v2') if captain_v2_enabled_by_default?
    account.enable_features(*manually_managed_features)
    update_shopify_managed_features
    account.save!
  end

  private

  def current_plan_features
    return [] if default_plan?
    return Enterprise::Billing::PlanConfiguration.current_plan!(account).fetch('features') if shopify_billing?

    case account.custom_attributes['plan_name']
    when 'Startups' then STARTUP_PLAN_FEATURES
    when 'Business' then STARTUP_PLAN_FEATURES + BUSINESS_PLAN_FEATURES
    when 'Enterprise' then PREMIUM_PLAN_FEATURES
    else []
    end
  end

  def default_plan?
    return account.custom_attributes['plan_name'].blank? if shopify_billing?

    default_plan_name = cloud_plans.first&.dig('name')
    return false if default_plan_name.blank?

    plan_name = account.custom_attributes['plan_name']
    plan_name.blank? || plan_name == default_plan_name
  end

  def cloud_plans
    @cloud_plans ||= InstallationConfig.find_by(name: CLOUD_PLANS_CONFIG)&.value || []
  end

  def managed_plan_features
    return PREMIUM_PLAN_FEATURES unless shopify_billing?

    (SHOPIFY_BASE_MANAGED_FEATURES + previously_managed_shopify_features + current_shopify_catalog_features).uniq
  end

  def previously_managed_shopify_features
    Array(account.internal_attributes[SHOPIFY_MANAGED_FEATURES])
  end

  def current_shopify_catalog_features
    return @current_shopify_catalog_features if defined?(@current_shopify_catalog_features)

    plans = Enterprise::Billing::PlanConfiguration.plans_for(account)
    @current_shopify_catalog_features = plans.flat_map { |plan| plan.fetch('features') }.uniq
  end

  def update_shopify_managed_features
    return unless shopify_billing?

    account.internal_attributes[SHOPIFY_MANAGED_FEATURES] = current_shopify_catalog_features
  end

  def shopify_billing?
    account.billing_provider == 'shopify'
  end

  def captain_v2_enabled_by_default?
    !shopify_billing? && !default_plan?
  end

  def manually_managed_features
    @manually_managed_features ||= Internal::Accounts::InternalAttributesService.new(account).manually_managed_features
  end
end
