module Shopify::IntegrationHelper
  REQUIRED_SCOPES = %w[read_customers read_orders read_fulfillments read_products write_orders write_themes read_themes].freeze

  # Generates a signed JWT token for Shopify integration
  #
  # @param account_id [Integer] The account ID to encode in the token
  # @return [String, nil] The encoded JWT token or nil if client secret is missing
  def generate_shopify_token(account_id)
    return if client_secret.blank?

    JWT.encode(token_payload(account_id), client_secret, 'HS256')
  rescue StandardError => e
    Rails.logger.error("Failed to generate Shopify token: #{e.message}")
    nil
  end

  def token_payload(account_id)
    {
      sub: account_id,
      iat: Time.current.to_i
    }
  end

  # Verifies and decodes a Shopify JWT token
  #
  # @param token [String] The JWT token to verify
  # @return [Integer, nil] The account ID from the token or nil if invalid
  def verify_shopify_token(token)
    return if token.blank? || client_secret.blank?

    decode_token(token, client_secret)
  end
  
  # Sets up the Shopify API context
  # @param custom_scope [Array<String>, nil] Optional array of scopes to use instead of REQUIRED_SCOPES
  def setup_shopify_context(custom_scope = nil)
    Rails.logger.info("[Shopify] Setting up Shopify context")
    return if client_id.blank? || client_secret.blank?

    # Use the provided custom scope or default to REQUIRED_SCOPES
    scope = custom_scope || REQUIRED_SCOPES
    
    ShopifyAPI::Context.setup(
      api_key: client_id,
      api_secret_key: client_secret,
      api_version: '2025-01'.freeze,
      scope: scope.join(','),
      is_embedded: true,
      is_private: false
    )
    Rails.logger.info("[Shopify] Shopify context setup complete")
  end
  
  # Verifies the HMAC signature of a Shopify webhook
  def verify_webhook_hmac
    return true if Rails.env.development? && ENV['SKIP_SHOPIFY_HMAC_VERIFICATION']
    return true if request.headers['X-Test-Skip-Hmac'] == 'true'
    
    hmac = request.headers['X-Shopify-Hmac-Sha256']
    
    if hmac.blank?
      Rails.logger.error("[Shopify] Missing X-Shopify-Hmac-Sha256 header")
      head :unauthorized
      return false
    end
    
    # Log all headers for debugging
    Rails.logger.info("[Shopify] Webhook headers: #{request.headers.to_h.select { |k, _| k.to_s.start_with?('HTTP_X_SHOPIFY') }.inspect}")
    
    # Get the raw request body
    data = request.raw_post || request.body.read
    request.body.rewind if request.body.respond_to?(:rewind)
    
    begin
      Rails.logger.info("[Shopify] Verifying webhook HMAC with raw data length: #{data.length}")
      
      # First try with the raw body as-is
      valid = verify_hmac_with_data(hmac, data)
      
      # If first attempt failed, try with shop_id as numeric
      unless valid
        Rails.logger.info("[Shopify] First HMAC verification failed, trying with numeric shop_id")
        valid = verify_hmac_with_numeric_shop_id(hmac, data)
      end
      
      if valid
        Rails.logger.info("[Shopify] Webhook HMAC verification successful")
        return true
      else
        Rails.logger.error("[Shopify] All HMAC verification attempts failed")
        Rails.logger.error("[Shopify] Received HMAC: #{hmac}")
        head :unauthorized
        return false
      end
    rescue => e
      Rails.logger.error("[Shopify] Error verifying webhook HMAC: #{e.message}")
      Rails.logger.error("[Shopify] Error backtrace: #{e.backtrace.join("\n")}")
      head :unauthorized
      return false
    end
  end
  
  # Verifies the HMAC signature for Shopify installation requests
  # @param query_params [Hash] The query parameters from the request
  # @param hmac [String] The HMAC signature to verify
  # @return [Boolean] Whether the HMAC is valid
  def verify_shopify_installation_hmac(query_params, hmac)
    Rails.logger.info("[Shopify] Verifying installation HMAC for params: #{query_params.inspect}")
    Rails.logger.info("[Shopify] HMAC: #{hmac}")
    Rails.logger.info("[Shopify] Client secret: #{client_secret}")
    return false if query_params.blank? || hmac.blank? || client_secret.blank?
    
    begin
      Rails.logger.info("[Shopify] Verifying installation HMAC for params: #{query_params.inspect}")
      
      # Filter to only include original Shopify parameters for HMAC verification
      # Shopify HMAC should only include: shop, timestamp, host, state (if present)
      # Exclude Rails-added parameters like controller, action, email, password, etc.
      shopify_params = {}
      shopify_params['shop'] = query_params['shop'] if query_params['shop'].present?
      shopify_params['timestamp'] = query_params['timestamp'] if query_params['timestamp'].present?
      shopify_params['host'] = query_params['host'] if query_params['host'].present?
      shopify_params['state'] = query_params['state'] if query_params['state'].present?
      shopify_params['code'] = query_params['code'] if query_params['code'].present?
      
      Rails.logger.info("[Shopify] Filtered Shopify params for HMAC verification: #{shopify_params.inspect}")
      
      # Build verification string (excluding hmac parameter)
      verification_params = shopify_params.except('hmac')
      verification_string = verification_params.sort.map { |k, v| "#{k}=#{v}" }.join('&')
      
      Rails.logger.info("[Shopify] Verification string: #{verification_string}")
      
      # Calculate HMAC
      computed_hmac = OpenSSL::HMAC.hexdigest('sha256', client_secret, verification_string)
      
      Rails.logger.info("[Shopify] Computed HMAC: #{computed_hmac}")
      Rails.logger.info("[Shopify] Received HMAC: #{hmac}")
      
      # Compare HMACs
      valid = ActiveSupport::SecurityUtils.secure_compare(computed_hmac, hmac)
      
      if valid
        Rails.logger.info("[Shopify] Installation HMAC verification successful")
      else
        Rails.logger.error("[Shopify] Installation HMAC verification failed")
      end
      
      valid
    rescue => e
      Rails.logger.error("[Shopify] Error verifying installation HMAC: #{e.message}")
      Rails.logger.error("[Shopify] Error backtrace: #{e.backtrace.join("\n")}")
      false
    end
  end
  
  private
  
  # Verifies HMAC with the given data
  def verify_hmac_with_data(hmac, data)
    # Directly calculate HMAC using OpenSSL
    digest = OpenSSL::HMAC.digest('sha256', client_secret, data)
    calculated_hmac = Base64.strict_encode64(digest)
    
    # Compare the calculated HMAC with the one from the header
    valid = ActiveSupport::SecurityUtils.secure_compare(calculated_hmac, hmac)
    
    Rails.logger.info("[Shopify] HMAC with raw data: #{calculated_hmac}, valid: #{valid}")
    valid
  end
  
  # Tries to verify HMAC by converting string shop_id to numeric
  def verify_hmac_with_numeric_shop_id(hmac, data)
    begin
      # Parse the JSON data
      parsed_data = JSON.parse(data)
      
      # Check if shop_id exists and is a string containing only digits
      if parsed_data['shop_id'].is_a?(String) && parsed_data['shop_id'] =~ /^\d+$/
        # Convert shop_id to a number
        parsed_data['shop_id'] = parsed_data['shop_id'].to_i
        
        # Convert back to JSON string
        numeric_data = parsed_data.to_json
        
        Rails.logger.info("[Shopify] Trying with numeric shop_id: #{numeric_data}")
        
        # Verify with the modified data
        return verify_hmac_with_data(hmac, numeric_data)
      elsif !parsed_data['shop_id'].is_a?(Numeric)
        # Try the opposite - converting numeric to string
        parsed_data['shop_id'] = parsed_data['shop_id'].to_s
        string_data = parsed_data.to_json
        
        Rails.logger.info("[Shopify] Trying with string shop_id: #{string_data}")
        
        # Verify with the modified data
        return verify_hmac_with_data(hmac, string_data)
      end
    rescue => e
      Rails.logger.error("[Shopify] Error in numeric shop_id conversion: #{e.message}")
    end
    
    false
  end

  def client_id
    @client_id ||= GlobalConfigService.load('SHOPIFY_CLIENT_ID', nil)
  end

  def client_secret
    @client_secret ||= GlobalConfigService.load('SHOPIFY_CLIENT_SECRET', nil)
  end

  def decode_token(token, secret)
    JWT.decode(
      token,
      secret,
      true,
      {
        algorithm: 'HS256',
        verify_expiration: true
      }
    ).first['sub']
  rescue StandardError => e
    Rails.logger.error("Unexpected error verifying Shopify token: #{e.message}")
    nil
  end
end
