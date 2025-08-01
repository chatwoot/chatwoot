module DashassistShopify
  class TokenManager
    attr_reader :shop_domain

    def initialize(shop_domain)
      @shop_domain = shop_domain
    end

    # Get the access token for a shop, checking both ShopifySession and Integrations::Hook
    def access_token
      # First try to get from ShopifySession (primary source)
      session = Dashassist::ShopifySession.find_by(shop: shop_domain)
      return session.access_token if session&.access_token.present?

      # Fallback to Integrations::Hook
      hook = find_shopify_hook
      return hook.access_token if hook&.access_token.present?

      nil
    end

    # Get the scope for a shop
    def scope
      # First try to get from ShopifySession
      session = Dashassist::ShopifySession.find_by(shop: shop_domain)
      return session.scope if session&.scope.present?

      # Fallback to Integrations::Hook settings
      hook = find_shopify_hook
      return hook.settings['scope'] if hook&.settings&.dig('scope').present?

      []
    end

    # Check if the shop has a valid token
    def has_valid_token?
      access_token.present?
    end

    # Check if the session is expired
    def session_expired?
      session = Dashassist::ShopifySession.find_by(shop: shop_domain)
      return true unless session
      
      session.expired?
    end

    # Store token in both ShopifySession and Integrations::Hook
    def store_token(access_token, scope = [], expires_at = nil)
      expires_at ||= 100.years.from_now # Default for Shopify tokens
      scope_array = scope.is_a?(Array) ? scope : scope.to_s.split(',')

      ActiveRecord::Base.transaction do
        # Store in ShopifySession
        session = Dashassist::ShopifySession.find_or_initialize_by(shop: shop_domain)
        session.update!(
          access_token: access_token,
          scope: scope_array,
          expires_at: expires_at
        )

        # Store in Integrations::Hook if account exists
        store = Dashassist::ShopifyStore.find_by(shop: shop_domain)
        if store
          hook = store.account.hooks.find_or_initialize_by(app_id: 'shopify')
          hook.update!(
            access_token: access_token,
            status: 'enabled',
            reference_id: shop_domain,
            settings: {
              scope: scope_array.join(',')
            }
          )
        end

        # Re-enable the web widget when tokens are restored
        enable_web_widget
      end
    end

    # Remove token from both storage locations
    def remove_token
      ActiveRecord::Base.transaction do
        # Remove from ShopifySession
        session = Dashassist::ShopifySession.find_by(shop: shop_domain)
        session&.destroy

        # Remove from Integrations::Hook
        store = Dashassist::ShopifyStore.find_by(shop: shop_domain)
        if store
          hook = store.account.hooks.find_by(app_id: 'shopify')
          hook&.destroy
        end
      end
    end

    # Get shop information including account and inbox
    def shop_info
      store = Dashassist::ShopifyStore.find_by(shop: shop_domain)
      return nil unless store

      {
        shop: shop_domain,
        account_id: store.account_id,
        inbox_id: store.inbox_id,
        enabled: store.enabled,
        access_token: access_token,
        scope: scope
      }
    end

    # Validate token by making a test API call
    def validate_token
      return false unless has_valid_token?

      begin
        # Setup Shopify context
        setup_shopify_context
        
        # Create client with the token
        client = ShopifyAPI::Clients::Rest::Admin.new(
          session: ShopifyAPI::Auth::Session.new(
            shop: shop_domain,
            access_token: access_token
          )
        )
        
        # Try a simple API call to validate token
        response = client.get(path: "shop")
        response.code == 200
      rescue => e
        Rails.logger.error("[DashassistShopify::TokenManager] Token validation failed for shop: #{shop_domain}: #{e.message}")
        false
      end
    end

    # Refresh token if needed (for future use with refresh tokens)
    def refresh_token_if_needed
      return false unless session_expired?

      # For now, Shopify tokens don't expire, but this method is here for future use
      # when refresh tokens are implemented
      Rails.logger.warn("[DashassistShopify::TokenManager] Token expired for shop: #{shop_domain}")
      false
    end

    private

    def find_shopify_hook
      store = Dashassist::ShopifyStore.find_by(shop: shop_domain)
      return nil unless store

      store.account.hooks.find_by(app_id: 'shopify')
    end

    def setup_shopify_context
      client_id = GlobalConfigService.load('SHOPIFY_CLIENT_ID', nil)
      client_secret = GlobalConfigService.load('SHOPIFY_CLIENT_SECRET', nil)
      
      return if client_id.blank? || client_secret.blank?

      ShopifyAPI::Context.setup(
        api_key: client_id,
        api_secret_key: client_secret,
        api_version: '2025-01'.freeze,
        scope: scope.join(','),
        is_embedded: true,
        is_private: false
      )
    end

    # Re-enable the web widget when tokens are restored
    def enable_web_widget
      store = Dashassist::ShopifyStore.find_by(shop: shop_domain)
      
      if store
        Rails.logger.info("[DashassistShopify::TokenManager] Re-enabling web widget for shop: #{shop_domain}")
        store.update!(enabled: true)
        Rails.logger.info("[DashassistShopify::TokenManager] Successfully re-enabled web widget for shop: #{shop_domain}")
      else
        Rails.logger.warn("[DashassistShopify::TokenManager] No Shopify store found for shop: #{shop_domain}")
      end
    end
  end
end 