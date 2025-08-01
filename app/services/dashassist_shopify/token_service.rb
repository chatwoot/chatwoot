module DashassistShopify
  class TokenService
    class << self
      # Store a new token for a shop
      def store_token(shop_domain, access_token, scope = [], expires_at = nil)
        token_manager = TokenManager.new(shop_domain)
        token_manager.store_token(access_token, scope, expires_at)
        
        Rails.logger.info("[DashassistShopify::TokenService] Stored token for shop: #{shop_domain}")
        store_token
      end

      # Get access token for a shop
      def get_access_token(shop_domain)
        token_manager = TokenManager.new(shop_domain)
        token_manager.access_token
      end

      # Check if shop has valid token
      def has_valid_token?(shop_domain)
        token_manager = TokenManager.new(shop_domain)
        token_manager.has_valid_token?
      end

      # Validate token by making API call
      def validate_token(shop_domain)
        token_manager = TokenManager.new(shop_domain)
        token_manager.validate_token
      end

      # Remove token for a shop
      def remove_token(shop_domain)
        token_manager = TokenManager.new(shop_domain)
        token_manager.remove_token
        
        Rails.logger.info("[DashassistShopify::TokenService] Removed token for shop: #{shop_domain}")
      end

      # Get complete shop information
      def get_shop_info(shop_domain)
        token_manager = TokenManager.new(shop_domain)
        token_manager.shop_info
      end

      # Create Shopify API client for a shop
      def create_api_client(shop_domain)
        token_manager = TokenManager.new(shop_domain)
        return nil unless token_manager.has_valid_token?

        # Setup Shopify context
        setup_shopify_context(token_manager.scope)
        
        ShopifyAPI::Clients::Rest::Admin.new(
          session: ShopifyAPI::Auth::Session.new(
            shop: shop_domain,
            access_token: token_manager.access_token
          )
        )
      end

      # Create GraphQL client for a shop
      def create_graphql_client(shop_domain)
        token_manager = TokenManager.new(shop_domain)
        return nil unless token_manager.has_valid_token?

        # Setup Shopify context
        setup_shopify_context(token_manager.scope)
        
        ShopifyAPI::Clients::Graphql::Admin.new(
          session: ShopifyAPI::Auth::Session.new(
            shop: shop_domain,
            access_token: token_manager.access_token
          )
        )
      end

      # Batch remove tokens for multiple shops
      def remove_tokens_for_shops(shop_domains)
        results = {}
        
        shop_domains.each do |shop_domain|
          begin
            remove_token(shop_domain)
            results[shop_domain] = { success: true }
          rescue => e
            Rails.logger.error("[DashassistShopify::TokenService] Failed to remove token for shop: #{shop_domain}: #{e.message}")
            results[shop_domain] = { success: false, error: e.message }
          end
        end
        
        results
      end

      # Find shops with expired sessions
      def find_shops_with_expired_sessions
        Dashassist::ShopifySession.where('expires_at < ?', Time.current).pluck(:shop)
      end

      # Clean up expired sessions
      def cleanup_expired_sessions
        expired_shops = find_shops_with_expired_sessions
        
        expired_shops.each do |shop_domain|
          Rails.logger.info("[DashassistShopify::TokenService] Cleaning up expired session for shop: #{shop_domain}")
          remove_token(shop_domain)
        end
        
        expired_shops.count
      end

      private

      def setup_shopify_context(scope = [])
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
    end
  end
end 