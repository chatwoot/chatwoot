class Enterprise::Billing::SummaryService
  SHOPIFY_SNAPSHOT_KEY = 'shopify_subscription_snapshot'.freeze
  SHOPIFY_REFRESH_ERRORS = [
    Enterprise::Billing::ShopifySubscriptionSyncService::InvalidSubscription,
    Enterprise::Billing::PlanConfiguration::InvalidConfiguration,
    Shopify::SubscriptionFetcher::NotEligible,
    Shopify::PartnerClient::ConfigurationError,
    Shopify::PartnerClient::ProviderError,
    Shopify::ShopIdentity::ProviderError,
    ActiveRecord::RecordNotFound
  ].freeze

  class RefreshError < StandardError; end

  def initialize(account:)
    @account = account
  end

  def perform(refresh: false)
    account.billing_provider == 'shopify' ? shopify_summary(refresh: refresh) : stripe_summary
  end

  private

  attr_reader :account

  def stripe_summary
    attributes = account.custom_attributes

    {
      provider: account.billing_provider,
      state: attributes['subscription_status'].presence || 'pending',
      plan: plan_payload(name: attributes['plan_name']),
      amount: nil,
      currency: normalized_currency(account.billing_currency),
      billing_period: nil,
      trial_ends_at: nil,
      current_period_end: attributes['subscription_ends_on'],
      allowed_actions: stripe_allowed_actions,
      last_verified_at: nil
    }
  end

  def shopify_summary(refresh:)
    snapshot = shopify_snapshot(refresh: refresh)
    attributes = account.custom_attributes
    handle = snapshot['plan_handles']&.one? ? snapshot['plan_handles'].first : nil

    {
      provider: account.billing_provider,
      state: snapshot['state'].presence || attributes['subscription_status'].presence || 'pending',
      plan: plan_payload(name: attributes['plan_name'] || snapshot['plan_name'], handle: handle),
      amount: snapshot['amount'],
      currency: normalized_currency(snapshot['currency'] || attributes['billing_currency']),
      billing_period: snapshot['billing_period'],
      trial_ends_at: snapshot['trial_ends_at'],
      current_period_end: snapshot['current_period_end'],
      allowed_actions: shopify_allowed_actions,
      last_verified_at: snapshot['verified_at']
    }
  end

  def shopify_snapshot(refresh:)
    return account.custom_attributes.fetch(SHOPIFY_SNAPSHOT_KEY, {}) unless refresh

    refreshed_snapshot = Enterprise::Billing::ShopifySubscriptionSyncService.new(account: account).perform
    raise RefreshError, 'Shopify billing refresh is unavailable' if refreshed_snapshot.blank?

    account.reload
    account.custom_attributes.fetch(SHOPIFY_SNAPSHOT_KEY, {})
  rescue *SHOPIFY_REFRESH_ERRORS => e
    raise RefreshError, 'Shopify billing refresh failed', cause: e
  end

  def plan_payload(name:, handle: nil)
    return if name.blank? && handle.blank?

    { name: name, handle: handle }.compact
  end

  def normalized_currency(currency)
    currency.to_s.upcase.presence
  end

  def stripe_allowed_actions
    currency_selection_required = account.billing_currency_selection_required?
    stripe_customer_present = account.custom_attributes['stripe_customer_id'].present?

    {
      start_subscription: !currency_selection_required && !stripe_customer_present,
      manage_subscription: stripe_customer_present,
      select_billing_currency: currency_selection_required,
      purchase_credits: stripe_topup_available?
    }
  end

  def shopify_allowed_actions
    {
      start_subscription: false,
      manage_subscription: true,
      select_billing_currency: false,
      purchase_credits: false
    }
  end

  def stripe_topup_available?
    attributes = account.custom_attributes
    return false if attributes['stripe_customer_id'].blank? || attributes['plan_name'].blank?

    default_plan_name = Enterprise::Billing::PlanConfiguration.default_plan&.dig('name')
    default_plan_name.blank? || !attributes['plan_name'].casecmp?(default_plan_name)
  end
end
