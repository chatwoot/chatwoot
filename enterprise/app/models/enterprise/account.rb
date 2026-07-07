module Enterprise::Account
  # Transitional marker for the Captain V1 to V2 rollout. New cloud accounts get
  # this marker so plan reconciliation can enable V2 for them without upgrading
  # existing paid accounts. Remove once every account is migrated to V2.
  CAPTAIN_V2_DEFAULT_ELIGIBLE = 'captain_v2_default_eligible'.freeze

  class << self
    def captain_document_sync_intervals
      parse_captain_document_sync_intervals(InstallationConfig.find_by(name: 'CAPTAIN_DOCUMENT_AUTO_SYNC_INTERVALS')&.value)
    end

    private

    def parse_captain_document_sync_intervals(configured_intervals)
      return {} if configured_intervals.blank?

      parsed_intervals = configured_intervals.is_a?(String) ? JSON.parse(configured_intervals) : configured_intervals
      return {} unless parsed_intervals.is_a?(Hash)

      parsed_intervals.transform_keys { |plan| plan.to_s.downcase }
    rescue JSON::ParserError
      {}
    end
  end

  # TODO: Remove this when we upgrade administrate gem to the latest version
  # this is a temporary method since current administrate doesn't support virtual attributes
  def manually_managed_features; end

  # Auto-sync advanced_assignment with assignment_v2 when features are bulk-updated via admin UI
  def selected_feature_flags=(features)
    super
    sync_assignment_features
  end

  def mark_for_deletion(reason = 'manual_deletion')
    reason = reason.to_s == 'manual_deletion' ? 'manual_deletion' : 'inactivity'

    result = custom_attributes.merge!(
      'marked_for_deletion_at' => 7.days.from_now.iso8601,
      'marked_for_deletion_reason' => reason
    ) && save

    # Send notification to admin users if the account was successfully marked for deletion
    if result
      mailer = AdministratorNotifications::AccountNotificationMailer.with(account: self)
      if reason == 'manual_deletion'
        mailer.account_deletion_user_initiated(self, reason).deliver_later
      else
        mailer.account_deletion_for_inactivity(self, reason).deliver_later
      end
    end

    result
  end

  def unmark_for_deletion
    custom_attributes.delete('marked_for_deletion_at') && custom_attributes.delete('marked_for_deletion_reason') && save
  end

  def captain_document_sync_interval(sync_intervals = Enterprise::Account.captain_document_sync_intervals)
    plan = custom_attributes['plan_name']
    plan = 'enterprise' if plan.blank? && ChatwootApp.self_hosted_enterprise?
    return nil if plan.blank?

    interval_hours = sync_intervals[plan.downcase]
    return nil unless interval_hours.is_a?(Integer) && interval_hours.positive?

    interval_hours.hours
  end

  def saml_enabled?
    saml_settings&.saml_enabled? || false
  end

  def billing_currency
    # Feature off => everyone is billed in USD (legacy behaviour).
    return Enterprise::Billing::Currencies::DEFAULT unless Enterprise::Billing::Currencies.enabled?

    stored = custom_attributes&.dig('billing_currency')
    return Enterprise::Billing::Currencies.normalize(stored) if Enterprise::Billing::Currencies.supported?(stored)

    # Existing Stripe customers stay on USD (webhook backfills the real currency);
    # only brand-new accounts infer from locale, so existing pt_BR users aren't charged BRL.
    return Enterprise::Billing::Currencies::DEFAULT if custom_attributes&.dig('stripe_customer_id').present?

    Enterprise::Billing::Currencies.for_locale(locale)
  end

  # New accounts whose locale maps to a non-USD currency get to pick USD or that
  # currency before the Stripe customer is created; everyone else proceeds in USD.
  def billing_currency_selection_required?
    return false unless Enterprise::Billing::Currencies.enabled?
    return false if custom_attributes&.dig('stripe_customer_id').present?
    return false if Enterprise::Billing::Currencies.supported?(custom_attributes&.dig('billing_currency'))

    Enterprise::Billing::Currencies.for_locale(locale) != Enterprise::Billing::Currencies::DEFAULT
  end

  private

  def enable_default_features
    super
    if ChatwootApp.self_hosted_enterprise?
      enable_features('captain_integration', 'captain_integration_v2')
    elsif ChatwootApp.chatwoot_cloud?
      internal_attributes[CAPTAIN_V2_DEFAULT_ELIGIBLE] = true
    end
  end

  def sync_assignment_features
    if feature_enabled?('assignment_v2')
      # Enable advanced_assignment for Business/Enterprise plans
      send('feature_advanced_assignment=', true) if business_or_enterprise_plan?
    else
      # Disable advanced_assignment when assignment_v2 is disabled
      send('feature_advanced_assignment=', false)
    end
  end

  def business_or_enterprise_plan?
    plan_name = custom_attributes['plan_name']
    %w[Business Enterprise].include?(plan_name)
  end
end
