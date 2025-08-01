module DashassistShopify
  class InstallController < ApplicationController
    include Shopify::IntegrationHelper
    include ::ShopifySessionVerification

    INSTALLATION_SCOPES = (REQUIRED_SCOPES + %w[]).freeze

    before_action :setup_shopify_context, only: [:callback]
    before_action :set_cors_headers
    after_action :allow_iframe_requests

    def index
      Rails.logger.info("[Shopify Install] Starting installation process for shop: #{params[:shop]}")
      shop = params[:shop]
      
      # Log all parameters for debugging
      Rails.logger.info("[Shopify Install] Request parameters: #{params.to_json}")
      

      # Handle embedded app loads vs installation requests
      if params[:hmac].present?
        Rails.logger.info("[Shopify Install] HMAC detected without code for shop: #{shop}")
        
        # Check if we have a session for this shop
        existing_session = Dashassist::ShopifySession.find_by(shop: shop)
        # If embedded=1 parameter is present AND we have an existing session, 
        # this is an app load within Shopify admin
        if params[:embedded].present? && existing_session
          Rails.logger.info("[Shopify Install] Embedded app load detected with existing session - rendering app")
          @shop = shop
          render 'dashassist_shopify/install/index'
          return
        end
        
        # Validate HMAC for installation flow
        # Build query params with only the parameters that exist
        query_params = {
          shop: params[:shop],
          timestamp: params[:timestamp],
          hmac: params[:hmac]
        }
        
        # Only add state and host if they exist
        query_params[:state] = params[:state] if params[:state].present?
        query_params[:host] = params[:host] if params[:host].present?
        
        Rails.logger.info("[Shopify Install] Creating AuthQuery with params: #{query_params}")
        
        begin
          query = ShopifyAPI::Auth::Oauth::AuthQuery.new(query_params)
          
          # Verify HMAC signature
          if ShopifyAPI::Utils::HmacValidator.validate(query)
            Rails.logger.info("[Shopify Install] Valid HMAC signature - starting installation flow")
            # Redirect to OAuth to get a fresh token
            redirect_to shopify_oauth_url(shop), allow_other_host: true
            return
          else
            Rails.logger.error("[Shopify Install] Invalid HMAC signature for shop: #{shop}")
            return render json: { error: 'Invalid HMAC' }, status: :unauthorized
          end
        rescue => e
          Rails.logger.error("[Shopify Install] Error validating HMAC: #{e.message}")
          # If validation fails, redirect to OAuth anyway
          redirect_to shopify_oauth_url(shop), allow_other_host: true
          return
        end
      end
    end

    def callback
      Rails.logger.info("[Shopify Install] Starting OAuth callback for shop: #{params[:shop]}")
      Rails.logger.debug("[Shopify Install] Callback params: #{params.inspect}")
      
      begin
        Rails.logger.info("[Shopify Install] Exchanging code for access token using OAuth2 client")
        @response = oauth_client.auth_code.get_token(
          params[:code],
          redirect_uri: callback_url
        )
        Rails.logger.info("[Shopify Install] Successfully obtained access token")

        # Use TokenService to store the token consistently
        DashassistShopify::TokenService.store_token(
          params[:shop],
          parsed_body['access_token'],
          parsed_body['scope'].split(','),
          100.years.from_now # Shopify tokens don't expire
          )

        # Redirect to our app interface
        redirect_url = "https://#{params[:shop]}/admin/apps/#{client_id}"
        Rails.logger.info("[Shopify Install] Installation complete, redirecting to: #{redirect_url}")
        redirect_to redirect_url, allow_other_host: true
      rescue OAuth2::Error => e
        Rails.logger.error("[Shopify Install] OAuth error: #{e.message}")
        Rails.logger.error("[Shopify Install] Error details: #{e.response.body if e.respond_to?(:response)}")
        render json: { error: e.message }, status: :unprocessable_entity
      rescue StandardError => e
        Rails.logger.error("[Shopify Install] Unexpected error during Shopify OAuth: #{e.message}")
        Rails.logger.error("[Shopify Install] Error backtrace: #{e.backtrace.join("\n")}")
        render json: { error: 'An unexpected error occurred' }, status: :internal_server_error
      end
    end

    def setup_widget
      Rails.logger.info("[Shopify Install] Setting up web widget for shop: #{params[:shop]}")
      
      # Verify Shopify App Bridge session token first
      return unless verify_shopify_token
      
      # Get auth headers
      access_token = request.headers['access-token']
      client = request.headers['client']
      uid = request.headers['uid']
      shop_domain = request.headers['X-Shopify-Shop-Domain']

      Rails.logger.info("[Shopify Install] Auth headers: access_token=#{access_token.present? ? 'present' : 'missing'}, client=#{client.present? ? 'present' : 'missing'}, uid=#{uid.present? ? 'present' : 'missing'}")
      
      unless access_token && client && uid
        Rails.logger.error("[Shopify Install] Missing auth headers")
        return render json: { error: 'Authentication required' }, status: :unauthorized
      end

      # Get current user from auth headers
      current_user = User.find_by(uid: uid)
      unless current_user
        Rails.logger.error("[Shopify Install] No authenticated user found for uid: #{uid}")
        return render json: { error: 'Authentication required' }, status: :unauthorized
      end
      Rails.logger.info("[Shopify Install] Authenticated user: id=#{current_user.id}, email=#{current_user.email}")

      # First check if user has access to an existing account with this shop name
      account = current_user.accounts.find_by(name: params[:shop])
      
      # If no existing account, create a new one and grant access to the user
      unless account
        Rails.logger.info("[Shopify Install] No existing account found for shop: #{params[:shop]}, creating new account")
        account = Account.create!(
          name: params[:shop],
          domain: params[:shop]
        )
        
        # Grant access to the current user
        AccountUser.create!(
          account: account,
          user: current_user,
          role: 'administrator'
        )
        Rails.logger.info("[Shopify Install] Created new account and granted access to user: account_id=#{account.id}, user_id=#{current_user.id}")
      else
        Rails.logger.info("[Shopify Install] Using existing account: id=#{account.id}, name=#{account.name}")
      end

      # Check for existing Shopify web widget using includes and scope
      existing_widget = account.inboxes
                             .where(account_id: account.id)  # Ensure we only check inboxes belonging to this account
                             .where('lower(inboxes.name) = ?', 'shopify')
                             .where(channel_type: 'Channel::WebWidget')
                             .includes(:channel)
                             .first

      if existing_widget
        Rails.logger.info("[Shopify Install] Found existing Shopify web widget: inbox_id=#{existing_widget.id}, channel_id=#{existing_widget.channel_id}, channel_type=#{existing_widget.channel_type}")
        Rails.logger.info("[Shopify Install] Web widget details: website_url=#{existing_widget.channel.website_url}, widget_color=#{existing_widget.channel.widget_color}")
        render json: {
          status: 'existing',
          widget_script: existing_widget.channel.web_widget_script
        }
      else
        Rails.logger.info("[Shopify Install] No existing Shopify web widget found for account: id=#{account.id}")
        Rails.logger.info("[Shopify Install] Creating new Shopify web widget for shop: #{params[:shop]}")
        
        # Use the ShopifyInboxCreatorService to create all Shopify resources
        service = ShopifyInboxCreatorService.new(current_user, params[:shop])
        if service.create_inbox
          inbox = service.created_inbox
          if inbox
        Rails.logger.info("[Shopify Install] Successfully created Shopify web widget for shop: #{params[:shop]}")
        render json: {
          status: 'created',
              widget_script: inbox.channel.web_widget_script
        }
          else
            Rails.logger.error("[Shopify Install] Failed to find created inbox")
            render json: { error: 'Failed to create web widget' }, status: :internal_server_error
          end
        else
          Rails.logger.error("[Shopify Install] Failed to create Shopify resources")
          render json: { error: 'Failed to create web widget' }, status: :internal_server_error
        end
      end
    rescue StandardError => e
      Rails.logger.error("[Shopify Install] Error setting up web widget: #{e.message}")
      Rails.logger.error("[Shopify Install] Error backtrace: #{e.backtrace.join("\n")}")
      render json: { error: 'Failed to setup web widget' }, status: :internal_server_error
    end

    def toggle_widget
      Rails.logger.info("[Shopify Install] Toggling widget for shop: #{params[:shop]}")
      
      # Get Shopify session
      shopify_session = Dashassist::ShopifySession.find_by(shop: params[:shop])
      unless shopify_session
        Rails.logger.error("[Shopify Install] No Shopify session found for shop: #{params[:shop]}")
        return render json: { error: 'Shopify session not found' }, status: :not_found
      end

      # Setup Shopify context using the shared method
      setup_shopify_context(INSTALLATION_SCOPES)

      # Create GraphQL client
      graphql_client = ShopifyAPI::Clients::Graphql::Admin.new(
        session: ShopifyAPI::Auth::Session.new(
          shop: params[:shop],
          access_token: shopify_session.access_token
        )
      )

      begin
        # Get main theme with GraphQL
        themes_query = <<-GRAPHQL
          {
            themes(first: 10) {
              edges {
                node {
                  id
                  name
                  role
                }
              }
            }
          }
        GRAPHQL

        themes_response = graphql_client.query(query: themes_query)
        
        Rails.logger.info("[Shopify Install] Themes response: #{themes_response.inspect}")
        
        theme_edges = themes_response.body['data']['themes']['edges']
        Rails.logger.info("[Shopify Install] Theme edges: #{theme_edges.inspect}")
        
        main_theme = theme_edges.find { |edge| edge['node']['role'] == 'MAIN' }
        
        unless main_theme
          Rails.logger.error("[Shopify Install] No main theme found for shop: #{params[:shop]}")
          return render json: { error: 'Main theme not found' }, status: :not_found
        end

        theme_id = main_theme['node']['id']
        Rails.logger.info("[Shopify Install] Found main theme: #{theme_id}")

        # Get the theme.liquid asset with GraphQL
        asset_query = <<-GRAPHQL
          {
            theme(id: "#{theme_id}") {
              files(filenames: ["layout/theme.liquid", "theme.liquid"], first: 10) {
                edges {
                  node {
                    filename
                    body {
                      ... on OnlineStoreThemeFileBodyText {
                        content
                      }
                    }
                  }
                }
              }
            }
          }
        GRAPHQL

        asset_response = graphql_client.query(query: asset_query)
        
        Rails.logger.info("[Shopify Install] Asset response: #{asset_response.inspect}")
        
        # Check if we have results
        if asset_response.body['data'] && 
           asset_response.body['data']['theme'] && 
           asset_response.body['data']['theme']['files'] && 
           asset_response.body['data']['theme']['files']['edges'] && 
           !asset_response.body['data']['theme']['files']['edges'].empty?
          
          # Debug: Log all filenames found in the response
          filenames = asset_response.body['data']['theme']['files']['edges'].map { |edge| edge['node']['filename'] }
          Rails.logger.info("[Shopify Install] Files found in theme: #{filenames.inspect}")
          
          # Find the theme.liquid file in the results
          theme_liquid_file = asset_response.body['data']['theme']['files']['edges']
            .find { |edge| edge['node']['filename'] == 'layout/theme.liquid' }
          
          # If not found with layout/ prefix, try alternative locations
          if theme_liquid_file.nil?
            Rails.logger.info("[Shopify Install] Searching for theme.liquid in alternative locations")
            theme_liquid_file = asset_response.body['data']['theme']['files']['edges']
              .find { |edge| edge['node']['filename'] =~ /theme\.liquid$/i }
          end
          
          if theme_liquid_file
            theme_content = theme_liquid_file['node']['body']['content']
            theme_liquid_filename = theme_liquid_file['node']['filename']
            Rails.logger.info("[Shopify Install] Found theme.liquid at: #{theme_liquid_filename}")
          else
            # Try additional paths for theme.liquid
            Rails.logger.info("[Shopify Install] Theme.liquid not found in standard locations, trying additional paths")
            
            broader_query = <<-GRAPHQL
              {
                theme(id: "#{theme_id}") {
                  files(filenames: ["templates/theme.liquid", "sections/theme.liquid", "snippets/theme.liquid"], first: 10) {
                    edges {
                      node {
                        filename
                        body {
                          ... on OnlineStoreThemeFileBodyText {
                            content
                          }
                        }
                      }
                    }
                  }
                }
              }
            GRAPHQL
            
            broader_response = graphql_client.query(query: broader_query)
            
            if broader_response.body['data'] && 
               broader_response.body['data']['theme'] && 
               broader_response.body['data']['theme']['files'] && 
               broader_response.body['data']['theme']['files']['edges'] && 
               !broader_response.body['data']['theme']['files']['edges'].empty?
              
              broader_filenames = broader_response.body['data']['theme']['files']['edges'].map { |edge| edge['node']['filename'] }
              Rails.logger.info("[Shopify Install] Files found in additional paths: #{broader_filenames.inspect}")
              
              # Get the first file that was found
              theme_liquid_file = broader_response.body['data']['theme']['files']['edges'].first
              theme_content = theme_liquid_file['node']['body']['content']
              theme_liquid_filename = theme_liquid_file['node']['filename']
              Rails.logger.info("[Shopify Install] Found theme.liquid at: #{theme_liquid_filename}")
            else
              # Last resort - try to get all theme files and search for theme.liquid
              Rails.logger.info("[Shopify Install] No theme.liquid found in specific locations, fetching all theme files")
              
              all_files_query = <<-GRAPHQL
                {
                  theme(id: "#{theme_id}") {
                    files(first: 100) {
                      edges {
                        node {
                          filename
                          body {
                            ... on OnlineStoreThemeFileBodyText {
                              content
                            }
                          }
                        }
                      }
                    }
                  }
                }
              GRAPHQL
              
              all_files_response = graphql_client.query(query: all_files_query)
              
              if all_files_response.body['data'] && 
                 all_files_response.body['data']['theme'] && 
                 all_files_response.body['data']['theme']['files'] && 
                 all_files_response.body['data']['theme']['files']['edges'] && 
                 !all_files_response.body['data']['theme']['files']['edges'].empty?
                
                all_filenames = all_files_response.body['data']['theme']['files']['edges'].map { |edge| edge['node']['filename'] }
                Rails.logger.info("[Shopify Install] All theme files: #{all_filenames.inspect}")
                
                # Look for any file that might be the main layout file
                theme_liquid_file = all_files_response.body['data']['theme']['files']['edges']
                  .find { |edge| edge['node']['filename'] =~ /theme\.liquid$/i || edge['node']['filename'] =~ /main-layout\.liquid$/i }
                
                if theme_liquid_file
                  theme_content = theme_liquid_file['node']['body']['content']
                  theme_liquid_filename = theme_liquid_file['node']['filename']
                  Rails.logger.info("[Shopify Install] Found possible theme file at: #{theme_liquid_filename}")
                else
                  Rails.logger.error("[Shopify Install] Could not find theme.liquid or equivalent in theme files")
                  return render json: { error: 'Theme.liquid file not found' }, status: :unprocessable_entity
                end
              else
                Rails.logger.error("[Shopify Install] Failed to get any theme files")
                return render json: { error: 'Failed to get theme files' }, status: :unprocessable_entity
              end
            end
          end
        else
          Rails.logger.error("[Shopify Install] Failed to get theme asset: #{asset_response.body}")
          return render json: { error: 'Failed to get theme asset' }, status: :unprocessable_entity
        end

        # Get widget script
        widget_script = params[:widget_script]
        unless widget_script
          Rails.logger.error("[Shopify Install] No widget script provided")
          return render json: { error: 'Widget script required' }, status: :unprocessable_entity
        end

        # Extract the website token from the widget script
        widget_token = widget_script.match(/websiteToken:\s*'([^']+)'/)[1] rescue nil
        unless widget_token
          Rails.logger.error("[Shopify Install] Could not extract website token from widget script")
          return render json: { error: 'Invalid widget script format' }, status: :unprocessable_entity
        end

        # Check if any widget exists in the theme
        existing_widget = theme_content.match(/websiteToken:\s*'[^']+'/)

        # Update theme content based on toggle state
        if params[:is_active]
          updated_content = if existing_widget
                            # Replace existing widget with new one
                            theme_content.gsub(/<script>.*?websiteToken:\s*'[^']+'.*?<\/script>/m, widget_script)
                          else
                            # Add widget script if not already present
                            theme_content.gsub('</body>', "#{widget_script}\n</body>")
                          end

          Rails.logger.info("[Shopify Install] Updating theme content with widget script")
          
          # Build GraphQL mutation
          mutation_query = <<-GRAPHQL
            mutation {
              themeFilesUpsert(
                themeId: "#{theme_id}",
                files: [{
                  filename: "#{theme_liquid_filename || 'layout/theme.liquid'}",
                  body: {
                    type: TEXT,
                    value: "#{updated_content.gsub('"', '\"')}"  # Escape double quotes for GraphQL string
                  }
                }]
              ) {
                upsertedThemeFiles {
                  filename
                }
                userErrors {
                  field
                  message
                }
              }
            }
          GRAPHQL

          # Execute GraphQL mutation
          update_response = graphql_client.query(query: mutation_query)

          Rails.logger.info("[Shopify Install] GraphQL mutation: #{mutation_query}")
          Rails.logger.info("[Shopify Install] Update response: #{update_response.inspect}")
          
          if update_response.body['data'] && update_response.body['data']['themeFilesUpsert']
            if update_response.body['data']['themeFilesUpsert']['userErrors'].empty?
              Rails.logger.info("[Shopify Install] Successfully updated theme file")
              render json: { success: true }
            else
              errors = update_response.body['data']['themeFilesUpsert']['userErrors']
              Rails.logger.error("[Shopify Install] GraphQL errors: #{errors}")
              render json: { error: errors.map { |e| e['message'] }.join(', ') }, status: :unprocessable_entity
            end
          else
            Rails.logger.error("[Shopify Install] Unexpected GraphQL response: #{update_response.body}")
            render json: { error: 'Unexpected response from Shopify' }, status: :unprocessable_entity
          end
        else
          if existing_widget
            # Remove widget script if present
            updated_content = theme_content.gsub(/<script>.*?websiteToken:\s*'[^']+'.*?<\/script>/m, '')
            Rails.logger.info("[Shopify Install] Removing widget script from theme")
            
            # Build GraphQL mutation for removal
            mutation_query = <<-GRAPHQL
              mutation {
                themeFilesUpsert(
                  themeId: "#{theme_id}",
                  files: [{
                    filename: "#{theme_liquid_filename || 'layout/theme.liquid'}",
                    body: {
                      type: TEXT,
                      value: "#{updated_content.gsub('"', '\"')}"  # Escape double quotes for GraphQL string
                    }
                  }]
                ) {
                  upsertedThemeFiles {
                    filename
                  }
                  userErrors {
                    field
                    message
                  }
                }
              }
            GRAPHQL

            # Execute GraphQL mutation
            update_response = graphql_client.query(query: mutation_query)
            
            Rails.logger.info("[Shopify Install] GraphQL mutation for removal: #{mutation_query}")
            Rails.logger.info("[Shopify Install] Update response: #{update_response.inspect}")
            
            if update_response.body['data'] && update_response.body['data']['themeFilesUpsert']
              if update_response.body['data']['themeFilesUpsert']['userErrors'].empty?
                Rails.logger.info("[Shopify Install] Successfully removed widget from theme")
                render json: { success: true }
              else
                errors = update_response.body['data']['themeFilesUpsert']['userErrors']
                Rails.logger.error("[Shopify Install] GraphQL errors: #{errors}")
                render json: { error: errors.map { |e| e['message'] }.join(', ') }, status: :unprocessable_entity
              end
            else
              Rails.logger.error("[Shopify Install] Unexpected GraphQL response: #{update_response.body}")
              render json: { error: 'Unexpected response from Shopify' }, status: :unprocessable_entity
            end
          else
            Rails.logger.info("[Shopify Install] Widget not found in theme")
            render json: { success: true, message: 'Widget not found in theme' }
          end
        end
      rescue StandardError => e
        Rails.logger.error("[Shopify Install] Error toggling widget: #{e.message}")
        Rails.logger.error("[Shopify Install] Error backtrace: #{e.backtrace.join("\n")}")
        render json: { error: 'Failed to toggle widget' }, status: :internal_server_error
      end
    end

    def toggle_widget_using_script_tag
      Rails.logger.info("[Shopify Install] Toggling widget using ScriptTag for shop: #{params[:shop]}")
      
      begin
        # Get the Shopify session
        shopify_session = Dashassist::ShopifySession.find_by(shop: params[:shop])
        
        unless shopify_session
          Rails.logger.error("[Shopify Install] No valid session found for shop: #{params[:shop]}")
          return render json: { error: 'Shop not found' }, status: :not_found
        end
        
        # Initialize API client with session credentials
        shopify_api_client = ShopifyAPI::Clients::Rest::Admin.new(
          session: {
            shop: params[:shop],
            access_token: shopify_session.access_token
          }
        )
        
        # Get existing script tags
        existing_script_tags_response = shopify_api_client.get(path: "script_tags")
        existing_script_tags = existing_script_tags_response.body["script_tags"] || []
        
        # Check for our widget script
        widget_script = params[:widget_script]
        widget_script_url = ENV.fetch('WIDGET_SCRIPT_URL', nil)
        
        unless widget_script_url
          Rails.logger.error("[Shopify Install] WIDGET_SCRIPT_URL environment variable not set")
          return render json: { error: 'Widget script URL not configured' }, status: :unprocessable_entity
        end
        
        our_script_tag = existing_script_tags.find { |tag| tag["src"] == widget_script_url }
        
        if params[:is_active]
          if our_script_tag
            Rails.logger.info("[Shopify Install] Widget script already exists, updating")
            # Update existing script tag if needed
            shopify_api_client.put(
              path: "script_tags/#{our_script_tag['id']}",
              body: { 
                script_tag: { 
                  id: our_script_tag['id'],
                  event: 'onload',
                  src: widget_script_url
                } 
              }
            )
          else
            Rails.logger.info("[Shopify Install] Creating new script tag for widget")
            # Create new script tag
            shopify_api_client.post(
              path: "script_tags",
              body: { 
                script_tag: { 
                  event: 'onload',
                  src: widget_script_url
                } 
              }
            )
          end
          render json: { success: true, message: 'Widget enabled' }
        else
          # Remove script tag if it exists
          if our_script_tag
            Rails.logger.info("[Shopify Install] Removing widget script tag")
            shopify_api_client.delete(
              path: "script_tags/#{our_script_tag['id']}"
            )
            render json: { success: true, message: 'Widget disabled' }
          else
            Rails.logger.info("[Shopify Install] No widget script tag found to remove")
            render json: { success: true, message: 'Widget not found' }
          end
        end
      rescue StandardError => e
        Rails.logger.error("[Shopify Install] Error toggling widget script tag: #{e.message}")
        Rails.logger.error("[Shopify Install] Error backtrace: #{e.backtrace.join("\n")}")
        render json: { error: 'Failed to toggle widget' }, status: :internal_server_error
      end
    end

    private

    def set_cors_headers
      response.headers['Access-Control-Allow-Origin'] = "https://#{params[:shop]}"
      response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
      response.headers['Access-Control-Allow-Headers'] = 'Origin, Content-Type, Accept, Authorization, X-Requested-With'
      response.headers['Access-Control-Allow-Credentials'] = 'true'
    end

    def verify_shopify_token
      auth_header = request.headers['Authorization']
      if auth_header.present? && auth_header.start_with?('Bearer ')
        session_token = auth_header.gsub('Bearer ', '')
        
        unless verify_shopify_session_token(session_token)
          Rails.logger.error("[Shopify Install] Invalid or expired session token")
          render json: { error: 'Unauthorized: Invalid session token' }, status: :unauthorized
          return false
        end
        
        Rails.logger.info("[Shopify Install] Shopify session token verified successfully")
        return true
      else
        Rails.logger.error("[Shopify Install] Missing Authorization header with session token")
        render json: { error: 'Unauthorized: Missing session token' }, status: :unauthorized
        return false
      end
    end

    def allow_iframe_requests
      response.headers.delete('X-Frame-Options')
      # Set CSP header to allow embedding from Shopify admin
      response.headers['Content-Security-Policy'] = "frame-ancestors https://*.myshopify.com https://admin.shopify.com"
    end

    def find_valid_hook(shop)
      Rails.logger.debug("[Shopify Install] Searching for valid hook for shop: #{shop}")
      Integrations::Hook.find_by(
        app_id: 'shopify',
        reference_id: shop,
        status: 'enabled'
      )
    end

    def shopify_oauth_url(shop)
      Rails.logger.info("[Shopify Install] Generating OAuth URL for shop: #{shop}")
      nonce = SecureRandom.uuid
      state = generate_shopify_token(nonce)

      auth_url = "https://#{shop}/admin/oauth/authorize?"
      auth_url += URI.encode_www_form(
        client_id: client_id,
        scope: INSTALLATION_SCOPES.join(','),
        redirect_uri: callback_url,
        state: state
      )
      Rails.logger.debug("[Shopify Install] Generated OAuth URL: #{auth_url}")
      auth_url
    end

    def callback_url
      # Use the full URL from environment if set, otherwise construct from request
      url = ENV.fetch('SHOPIFY_CALLBACK_URL') do
        "#{request.protocol}#{request.host_with_port}/dashassist_shopify/callback"
      end
      
      Rails.logger.debug("[Shopify Install] Using callback URL: #{url}")
      if url.blank?
        Rails.logger.error("[Shopify Install] SHOPIFY_CALLBACK_URL is not set and could not be constructed")
        raise "SHOPIFY_CALLBACK_URL environment variable is required"
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
  end
end
