class Shopify::CallbackService
  def initialize(shop:)
    @shop = shop
  end

  def connect(account:, generation:, credentials:)
    Shopify::InstallationGeneration.with_current!(account, generation) do
      hook = account.hooks.find_or_initialize_by(app_id: 'shopify', reference_id: Shopify::ShopDomain.normalize(@shop))
      hook.update!(shopify_hook_attributes(credentials))
    end
  end

  def reconnect(account:, generation:, credentials:)
    Shopify::InstallationGeneration.with_current!(account, generation) do
      loop do
        hook = account.hooks.find_by(app_id: 'shopify')
        unless hook
          account.hooks.create!(shopify_hook_attributes(credentials))
          break
        end

        begin
          hook.with_lock { hook.update!(shopify_hook_attributes(credentials)) }
          break
        rescue ActiveRecord::RecordNotFound
          next
        end
      end
    end
  end

  def existing_account
    existing_shopify_hook&.account || shopify_billed_account_by_snapshot
  end

  def reusable_hook?(hook)
    return false unless hook&.enabled? && hook.access_token.present?

    granted_scopes = hook.settings['scope'].to_s.split(',').map(&:strip)
    (Shopify::IntegrationHelper::REQUIRED_SCOPES - granted_scopes).empty?
  end

  private

  def shopify_hook_attributes(credentials)
    {
      app_id: 'shopify',
      access_token: credentials['access_token'],
      status: 'enabled',
      reference_id: @shop,
      settings: shopify_hook_settings(credentials)
    }
  end

  def shopify_hook_settings(credentials)
    {
      scope: credentials['scope'],
      connected_at: Time.current.utc.iso8601(6),
      installation_id: SecureRandom.uuid
    }
  end

  def existing_shopify_hook
    @existing_shopify_hook ||=
      Integrations::Hook.where(app_id: 'shopify').find_sole_by('LOWER(reference_id) = ?', Shopify::ShopDomain.normalize(@shop))
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def shopify_billed_account_by_snapshot
    Account
      .where("internal_attributes ->> 'billing_provider' = ?", 'shopify')
      .where("internal_attributes ->> 'signup_source' = ?", 'shopify')
      .find_sole_by("custom_attributes #>> '{shopify_subscription_snapshot,shop_domain}' = ?",
                    Shopify::ShopDomain.normalize(@shop))
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
