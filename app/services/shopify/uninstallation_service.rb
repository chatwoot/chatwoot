class Shopify::UninstallationService
  def initialize(hook:)
    @hook = hook
    @account = hook.account
  end

  def perform
    return unless Shopify::FeatureGate.enabled?(account: account)
    return hook.destroy! unless shopify_billed_account?

    begin
      Enterprise::Billing::ShopifySubscriptionSyncService.new(account: account).perform(snapshot: uninstall_snapshot)
    ensure
      revoke_credentials
    end
  end

  private

  attr_reader :account, :hook

  def shopify_billed_account?
    account.billing_provider == 'shopify' && account.signup_source == 'shopify'
  end

  def uninstall_snapshot
    verified_at = Time.current.iso8601
    previous_snapshot = account.custom_attributes.fetch('shopify_subscription_snapshot', {})

    Shopify::SubscriptionSnapshot.from_h(
      previous_snapshot.slice('shop_id', 'shop_domain').merge(
        'state' => 'expired',
        'plan_handles' => [],
        'shop_domain' => hook.reference_id,
        'latest_event' => {
          'state' => 'RELATIONSHIP_UNINSTALLED',
          'occurred_at' => verified_at
        },
        'verified_at' => verified_at
      )
    )
  end

  def revoke_credentials
    hook.update!(status: :disabled, access_token: nil, settings: {})
  end
end
