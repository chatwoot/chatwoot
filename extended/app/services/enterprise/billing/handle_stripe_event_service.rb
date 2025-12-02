class Enterprise::Billing::HandleStripeEventService
  CLOUD_PLANS_CONFIG = 'CHATWOOT_CLOUD_PLANS'.freeze

  # Plan hierarchy: Hacker (default) -> Startups -> Business -> Enterprise
  # Each higher tier includes all features from the lower tiers

  # Basic features available starting with the Startups plan
  STARTUP_PLAN_FEATURES = %w[
    inbound_emails
    help_center
    campaigns
    team_management
    channel_twitter
    channel_facebook
    channel_email
    channel_instagram
    captain_integration
    advanced_search_indexing
    advanced_search
  ].freeze

  # Additional features available starting with the Business plan
  BUSINESS_PLAN_FEATURES = %w[sla custom_roles].freeze

  # Additional features available only in the Enterprise plan
  ENTERPRISE_PLAN_FEATURES = %w[audit_logs disable_branding saml].freeze

  def perform(_event:)
    Rails.logger.info 'Billing is disabled in this version of Chatwoot.'
  end

  private

  def process_subscription_updated; end
  def update_account_attributes(subscription, plan); end
  def process_subscription_deleted; end
  def update_plan_features; end
  def disable_all_premium_features; end
  def enable_features_for_current_plan; end
  def reset_captain_usage; end
  def enable_plan_specific_features; end
  def subscription; end
  def account; end
  def find_plan(plan_id); end
  def default_plan?; end
  def enable_account_manually_managed_features; end
end
