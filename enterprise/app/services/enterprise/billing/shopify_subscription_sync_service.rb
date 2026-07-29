class Enterprise::Billing::ShopifySubscriptionSyncService
  SNAPSHOT_KEY = 'shopify_subscription_snapshot'.freeze
  VERIFIED_AT_KEY = 'shopify_subscription_verified_at'.freeze
  SUSPENSION_MARKER = 'shopify_billing_suspended'.freeze
  SUSPENSION_REASON = 'Shopify App Pricing subscription is inactive'.freeze

  class InvalidSubscription < StandardError; end

  def initialize(account:)
    @account = account
  end

  def perform
    return unless eligible?

    snapshot = Shopify::SubscriptionFetcher.new(account: account).perform(force: true)
    reconciled = reconcile_snapshot(snapshot)
    return persisted_snapshot if reconciled == :stale
    return unless reconciled == :applied

    log_sync(snapshot)
    snapshot
  rescue InvalidSubscription, Enterprise::Billing::PlanConfiguration::InvalidConfiguration,
         Shopify::PartnerClient::ConfigurationError, Shopify::PartnerClient::ProviderError,
         Shopify::ShopIdentity::ProviderError, ActiveRecord::RecordNotFound => e
    log_failure(e)
    raise
  end

  private

  attr_reader :account

  def eligible?
    account.billing_provider == 'shopify' &&
      account.signup_source == 'shopify' &&
      Shopify::FeatureGate.enabled?(account: account)
  end

  def configured_plan(snapshot)
    handles = snapshot.plan_handles
    raise InvalidSubscription, 'Shopify subscription must have exactly one active plan handle' unless handles.one?

    Enterprise::Billing::PlanConfiguration.find_shopify_plan_by_handle(handles.first) ||
      raise(InvalidSubscription, 'Shopify subscription has an unknown plan handle')
  end

  def reconcile_snapshot(snapshot)
    account.with_lock do
      next false unless eligible?
      next :stale if stale_snapshot?(snapshot)

      plan = configured_plan(snapshot) if snapshot.entitled?
      snapshot.entitled? ? apply_entitlements(snapshot, plan) : remove_entitlements(snapshot)
      Enterprise::Billing::ReconcilePlanFeaturesService.new(account: account).perform
      :applied
    end
  end

  def stale_snapshot?(snapshot)
    persisted_verified_at = account.custom_attributes[VERIFIED_AT_KEY]
    return false if persisted_verified_at.blank?

    Time.iso8601(snapshot.to_h.fetch('verified_at')) <= Time.iso8601(persisted_verified_at)
  rescue ArgumentError
    raise InvalidSubscription, 'Shopify subscription has an invalid verification timestamp'
  end

  def persisted_snapshot
    Shopify::SubscriptionSnapshot.from_h(account.custom_attributes.fetch(SNAPSHOT_KEY))
  end

  def apply_entitlements(snapshot, plan)
    custom_attributes = subscription_attributes(snapshot).merge(
      'plan_name' => plan.fetch('name'),
      'subscription_status' => snapshot.state,
      'billing_currency' => snapshot.to_h['currency']
    )
    account.assign_attributes(custom_attributes: account.custom_attributes.merge(custom_attributes))
    restore_account_if_billing_suspended
    account.save!
  end

  def remove_entitlements(snapshot)
    custom_attributes = account.custom_attributes.merge(
      subscription_attributes(snapshot).merge(
        'plan_name' => nil,
        'subscription_status' => snapshot.state,
        'billing_currency' => nil
      )
    )
    account.assign_attributes(custom_attributes: custom_attributes)
    suspend_account_for_billing
    account.save!
  end

  def subscription_attributes(snapshot)
    {
      SNAPSHOT_KEY => snapshot.to_h,
      VERIFIED_AT_KEY => snapshot.to_h.fetch('verified_at')
    }
  end

  def suspend_account_for_billing
    return unless account.active?

    suspended_at = Time.current.iso8601
    suspension = {
      'category' => 'non_payment',
      'reason' => SUSPENSION_REASON,
      'suspended_at' => suspended_at
    }
    account.status = :suspended
    account.internal_attributes = account.internal_attributes.merge(
      SUSPENSION_MARKER => suspended_at,
      'suspensions' => account.suspension_history.map(&:dup) << suspension
    )
  end

  def restore_account_if_billing_suspended
    suspension_marker = account.internal_attributes[SUSPENSION_MARKER]
    return if suspension_marker.blank?

    internal_attributes = account.internal_attributes.deep_dup
    internal_attributes.delete(SUSPENSION_MARKER)
    account.internal_attributes = internal_attributes
    account.status = :active if shopify_owned_suspension?(suspension_marker)
  end

  def shopify_owned_suspension?(suspension_marker)
    account.suspended? &&
      account.suspension_history.last&.slice('category', 'reason', 'suspended_at') == {
        'category' => 'non_payment',
        'reason' => SUSPENSION_REASON,
        'suspended_at' => suspension_marker
      }
  end

  def log_sync(snapshot)
    Rails.logger.info(
      {
        event: 'shopify.subscription_sync.completed',
        account_id: account.id,
        state: snapshot.state,
        plan_handle: snapshot.plan_handles.one? ? snapshot.plan_handles.first : nil
      }.to_json
    )
  end

  def log_failure(error)
    Rails.logger.error(
      {
        event: 'shopify.subscription_sync.failed',
        account_id: account.id,
        error_class: error.class.name
      }.to_json
    )
  end
end
