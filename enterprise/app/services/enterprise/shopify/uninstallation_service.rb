module Enterprise::Shopify::UninstallationService
  private

  def uninstall
    return super unless shopify_billed_account?

    revoke_credentials
    Enterprise::Billing::ShopifySubscriptionSyncService.new(account: account).perform(snapshot: uninstall_snapshot)
  end

  def shopify_billed_account?
    account.billing_provider == 'shopify' && account.signup_source == 'shopify'
  end

  def uninstall_snapshot
    verified_at = Time.current.utc.iso8601(6)
    previous_snapshot = account.custom_attributes.fetch('shopify_subscription_snapshot', {})
    identity = delete_hook ? {} : previous_snapshot.slice('shop_id', 'shop_domain').merge('shop_domain' => hook.reference_id)

    Shopify::SubscriptionSnapshot.from_h(
      identity.merge(
        'state' => 'expired',
        'plan_handles' => [],
        'latest_event' => {
          'state' => 'RELATIONSHIP_UNINSTALLED',
          'occurred_at' => occurred_at&.utc&.iso8601(6) || verified_at
        },
        'verified_at' => verified_at
      )
    )
  end

  def revoke_credentials
    hook.update!(status: :disabled, access_token: nil, settings: {})
  end
end
