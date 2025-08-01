module DashassistShopify
  module Standalone
    class StandaloneController < ApplicationController
      include Shopify::IntegrationHelper
      include ::ShopifySessionVerification

      # Constants
      INSTALLATION_SCOPES = (REQUIRED_SCOPES + %w[]).freeze

      before_action :setup_standalone_context, only: [:callback]
      before_action :set_cors_headers

      def exists
        shop = params[:shop]
        store = Dashassist::ShopifyStore.find_by(shop: shop)
        
        render json: { exists: store.present? }
      end

      # Entry point for the standalone app installation
      def index
        Rails.logger.info("[Shopify Standalone] Starting request process for shop: #{params[:shop]}")
        shop = params[:shop]
        
        # Log all parameters for debugging
        Rails.logger.info("[Shopify Standalone] Request parameters: #{params.to_json}")
        
        # Check if the shop parameter is provided
        unless shop.present?
          Rails.logger.error("[Shopify Standalone] No shop parameter provided")
          return render json: { error: 'Shop parameter is required' }, status: :unprocessable_entity
        end

        # Detect if this is an installation request vs regular post-install access
        # Installation requests come from Shopify with specific parameters
        is_installation_request = params[:hmac].present? && params[:timestamp].present?
        Rails.logger.info("[Shopify Standalone] Request type: #{is_installation_request ? 'Installation' : 'Post-install access'}")
        
        # Check if we have a valid session and a valid entry in Shopify store
        shopify_store = Dashassist::ShopifyStore.find_by(shop: shop)
        shopify_session = Dashassist::ShopifySession.find_by(shop: shop)

        Rails.logger.info("[Shopify Standalone] Shopify store: #{shopify_store.inspect}")
        Rails.logger.info("[Shopify Standalone] Shopify session: #{shopify_session.inspect}")
        
        # Check if we have both a valid store entry and a valid session
        if shopify_store && shopify_session && !shopify_session.expired?
          # Validate the token to ensure it still works with the Shopify API
          token_valid = validate_access_token(shop, shopify_session.access_token)
          
          if token_valid
            Rails.logger.info("[Shopify Standalone] Valid session and store entry found - redirecting to login")
            # Redirect to login since we have both valid session and store
            # Preserve all query parameters
            query_params = request.query_parameters.except('hmac')
            login_url = build_frontend_url(FRONTEND_LOGIN_PATH, query_params)
            redirect_to login_url, allow_other_host: true
            return
          else
            # Token is invalid, this should never happen, log a warning
            Rails.logger.warn("[Shopify Standalone] Token invalid for shop: #{shop}")
            # Redirect to signup to complete setup
            # Preserve all query parameters
            query_params = request.query_parameters
            signup_url = build_frontend_url(FRONTEND_SIGNUP_PATH, query_params)
            redirect_to signup_url, allow_other_host: true
            return
          end
        elsif shopify_session && !shopify_session.expired?
          # We have a valid session but no store entry - redirect to signup to complete setup
          # Now we allow user to login to the app and then we will create the store entry
          Rails.logger.info("[Shopify Standalone] Valid session but no store entry - redirecting to signup")
          # Preserve all query parameters including HMAC
          query_params = request.query_parameters
          signup_url = build_frontend_url(FRONTEND_SIGNUP_PATH, query_params)
          redirect_to signup_url, allow_other_host: true
          return
        else
          # No valid session or store, need to go through installation
          Rails.logger.info("[Shopify Standalone] No valid session or store entry - treating as installation")
          # Continue to installation flow below
        end
        
        # We know we don't have a valid session. We need to go through the installation flow to get a new session.
        # For installation requests, we'll redirect to signup with all parameters preserved
        # HMAC verification will be handled in the frontend during signup/login
        
        # Start OAuth flow for installation
        Rails.logger.info("[Shopify Standalone] Initiating OAuth flow for shop: #{shop}")
        redirect_to shopify_oauth_url(shop), allow_other_host: true
      end

      def callback
        Rails.logger.info("[Shopify Standalone] Starting OAuth callback for shop: #{params[:shop]}")
        Rails.logger.debug("[Shopify Standalone] Callback params: #{params.inspect}")
        
        # Make sure we have required parameters
        unless params[:shop].present?
          Rails.logger.error("[Shopify Standalone] Missing shop parameter in callback")
          return render json: { error: 'Missing shop parameter' }, status: :unprocessable_entity
        end
        
        # Verify HMAC for callback request only when code parameter is present
        if params[:code].present?
          # Need to verify HMAC for the callback
          auth_query = ShopifyAPI::Auth::Oauth::AuthQuery.new(
            code: params[:code],
            shop: params[:shop],
            timestamp: params[:timestamp],
            state: params[:state],
            host: params[:host],
            hmac: params[:hmac]
          )
          
          unless ShopifyAPI::Utils::HmacValidator.validate(auth_query)
            Rails.logger.error("[Shopify Standalone] Invalid HMAC in callback for shop: #{params[:shop]}")
            return render json: { error: 'Invalid HMAC signature' }, status: :unauthorized
          end
          
          Rails.logger.info("[Shopify Standalone] Valid HMAC signature in callback - continuing OAuth flow")
        
          begin
            Rails.logger.info("[Shopify Standalone] Exchanging code for access token using OAuth2 client")
            @response = oauth_client.auth_code.get_token(
              params[:code],
              redirect_uri: standalone_callback_url
            )
            Rails.logger.info("[Shopify Standalone] Successfully obtained access token")

            # Find existing session or create new one
            shopify_session = Dashassist::ShopifySession.find_by(shop: params[:shop])
            
            if shopify_session
              Rails.logger.info("[Shopify Standalone] Updating existing session for shop: #{params[:shop]}")
              shopify_session.update!(
                access_token: parsed_body['access_token'],
                scope: parsed_body['scope'].split(','),
                expires_at: SESSION_EXPIRY
              )
            else
              Rails.logger.info("[Shopify Standalone] Creating new session for shop: #{params[:shop]}")
              shopify_session = Dashassist::ShopifySession.create!(
                shop: params[:shop],
                access_token: parsed_body['access_token'],
                scope: parsed_body['scope'].split(','),
                expires_at: SESSION_EXPIRY
              )
            end

          rescue OAuth2::Error => e
            Rails.logger.error("[Shopify Standalone] OAuth error: #{e.message}")
            Rails.logger.error("[Shopify Standalone] Error details: #{e.response.body if e.respond_to?(:response)}")
            return render json: { error: e.message }, status: :unprocessable_entity
          rescue StandardError => e
            Rails.logger.error("[Shopify Standalone] Unexpected error during Shopify OAuth: #{e.message}")
            Rails.logger.error("[Shopify Standalone] Error backtrace: #{e.backtrace.join("\n")}")
            return render json: { error: 'An unexpected error occurred' }, status: :internal_server_error
          end
        else
          Rails.logger.info("[Shopify Standalone] No code parameter in callback, skipping token exchange")
        end
        # # Always redirect to Chatwoot signup page with shop parameter
        # # Preserve all query parameters including HMAC for frontend verification
        # query_params = request.query_parameters

        # Redirect to Shopify pricing plans after successful OAuth
        shop_name = params[:shop].split('.')[0]
        pricing_url = "https://admin.shopify.com/store/#{shop_name}/charges/#{SHOPIFY_APP_HANDLE}/pricing_plans"
        Rails.logger.info("[Shopify Standalone] Callback complete, redirecting to pricing plans: #{pricing_url}")
        redirect_to pricing_url, allow_other_host: true
      end

      private

      def set_cors_headers
        response.headers['Access-Control-Allow-Origin'] = CORS_ALLOW_ORIGIN
        response.headers['Access-Control-Allow-Methods'] = CORS_ALLOW_METHODS
        response.headers['Access-Control-Allow-Headers'] = CORS_ALLOW_HEADERS
        response.headers['Access-Control-Allow-Credentials'] = CORS_ALLOW_CREDENTIALS
      end

      def verify_api_token
        # For API endpoints that need token verification
        auth_header = request.headers['Authorization']
        if auth_header.present? && auth_header.start_with?('Bearer ')
          token = auth_header.gsub('Bearer ', '')
          
          # Get shop from request
          shop = params[:shop]
          
          # Try to validate token using both approaches:
          # 1. As a JWT token with user ID
          user_id = verify_shopify_token(token)
          
          # 2. As a direct session token
          shopify_session = Dashassist::ShopifySession.find_by(shop: shop)
          
          if user_id || (shopify_session && shopify_session.access_token == token)
            Rails.logger.info("[Shopify Standalone] Token verified for shop: #{shop}")
            return true
          else
            Rails.logger.error("[Shopify Standalone] Invalid token for shop: #{shop}")
            render json: { error: 'Unauthorized: Invalid token' }, status: :unauthorized
            return false
          end
        else
          Rails.logger.error("[Shopify Standalone] Missing Authorization header")
          render json: { error: 'Unauthorized: Missing token' }, status: :unauthorized
          return false
        end
      end

      def shopify_oauth_url(shop)
        Rails.logger.info("[Shopify Standalone] Generating OAuth URL for shop: #{shop}")
        nonce = SecureRandom.uuid
        state = generate_shopify_token(nonce)

        auth_url = "https://#{shop}/admin/oauth/authorize?"
        auth_url += URI.encode_www_form(
          client_id: client_id,
          scope: INSTALLATION_SCOPES.join(','),
          redirect_uri: standalone_callback_url,
          state: state
        )
        Rails.logger.debug("[Shopify Standalone] Generated OAuth URL: #{auth_url}")
        auth_url
      end

      def standalone_callback_url
        # Use the full URL from environment if set, otherwise construct from request
        url = SHOPIFY_STANDALONE_CALLBACK_URL || "#{request.protocol}#{request.host_with_port}/dashassist_shopify/standalone/callback"
        
        Rails.logger.debug("[Shopify Standalone] Using callback URL: #{url}")
        if url.blank?
          Rails.logger.error("[Shopify Standalone] SHOPIFY_STANDALONE_CALLBACK_URL is not set and could not be constructed")
          # Fall back to regular callback URL
          return SHOPIFY_CALLBACK_URL || "#{request.protocol}#{request.host_with_port}/dashassist_shopify/callback"
        end
        url
      end

      def oauth_client
        OAuth2::Client.new(
          client_id,
          client_secret,
          {
            site: "https://#{params[:shop]}",
            authorize_url: '/admin/oauth/authorize',
            token_url: '/admin/oauth/access_token'
          }
        )
      end

      def parsed_body
        @parsed_body ||= @response.response.parsed
      end

      # Setup Shopify API context for non-embedded app
      def setup_standalone_context
        Rails.logger.info("[Shopify Standalone] Setting up Shopify context for non-embedded app")
        return if client_id.blank? || client_secret.blank?

        ShopifyAPI::Context.setup(
          api_key: client_id,
          api_secret_key: client_secret,
          api_version: API_VERSION,
          scope: INSTALLATION_SCOPES.join(','),
          is_embedded: false, # Important: this is a standalone non-embedded app
          is_private: false
        )
        Rails.logger.info("[Shopify Standalone] Shopify context setup complete")
      end

      # Validates a Shopify access token by making a test API call
      # @param shop [String] The shop domain
      # @param access_token [String] The access token to validate
      # @return [Boolean] Whether the token is valid
      def validate_access_token(shop, access_token)
        return false if shop.blank? || access_token.blank?
        
        begin
          Rails.logger.info("[Shopify Standalone] Validating access token for shop: #{shop}")
          
          # Setup context for API call
          setup_standalone_context
          
          # Create client with the token
          client = ShopifyAPI::Clients::Rest::Admin.new(
            session: ShopifyAPI::Auth::Session.new(
              shop: shop,
              access_token: access_token
            )
          )
          
          # Try a simple API call to validate token
          shop_response = client.get(path: "shop")
          valid = shop_response.code == 200
          
          if valid
            Rails.logger.info("[Shopify Standalone] Token validation successful for shop: #{shop}")
          else
            Rails.logger.info("[Shopify Standalone] Token validation failed for shop: #{shop} - invalid response code: #{shop_response.code}")
          end
          
          return valid
        rescue => e
          Rails.logger.info("[Shopify Standalone] Token validation failed for shop: #{shop}: #{e.message}")
          return false
        end
      end

      def build_frontend_url(path, query_params)
        base_url = FRONTEND_URL
        if base_url.end_with?('/')
          base_url = base_url[0...-1]
        end
        "#{base_url}#{path}?#{query_params.to_query}"
      end
    end
  end
end 