# Service to generate Facebook Conversions API access token
# Uses Business Manager API to create system user tokens for Conversions API
class Facebook::GenerateTokenService
  attr_reader :channel, :pixel_id

  def initialize(channel:, pixel_id:)
    @channel = channel
    @pixel_id = pixel_id
  end

  # Generate a Conversions API access token for the specified pixel
  def generate_conversions_api_token
    return { success: false, error: 'Facebook channel not configured' } unless channel.is_a?(Channel::FacebookPage)
    return { success: false, error: 'User access token not available' } unless user_access_token.present?
    return { success: false, error: 'Pixel ID is required' } unless pixel_id.present?

    begin
      # First, verify the pixel exists and user has access
      pixel_info = verify_pixel_access
      return { success: false, error: 'Pixel not found or access denied' } unless pixel_info

      # Try to get business ID from pixel
      business_id = get_business_id_from_pixel
      return { success: false, error: 'Could not determine business account for pixel' } unless business_id

      # Generate system user token for Conversions API
      token_result = generate_system_user_token(business_id)
      
      if token_result[:success]
        {
          success: true,
          access_token: token_result[:access_token],
          business_id: business_id,
          pixel_id: pixel_id
        }
      else
        token_result
      end
    rescue Koala::Facebook::AuthenticationError => e
      Rails.logger.error("Facebook authentication error in GenerateTokenService: #{e.message}")
      { success: false, error: 'Facebook authentication failed. Please reconnect your Facebook account.' }
    rescue Koala::Facebook::ClientError => e
      Rails.logger.error("Facebook client error in GenerateTokenService: #{e.message}")
      { success: false, error: 'Facebook API error. Please check your permissions.' }
    rescue StandardError => e
      Rails.logger.error("Error in GenerateTokenService: #{e.message}")
      { success: false, error: 'Failed to generate access token. Please try again.' }
    end
  end

  private

  def user_access_token
    @user_access_token ||= channel.user_access_token
  end

  def facebook_api
    @facebook_api ||= Koala::Facebook::API.new(user_access_token)
  end

  def verify_pixel_access
    begin
      # Try to get pixel information to verify access
      pixel_info = facebook_api.get_object(pixel_id, fields: 'id,name,creation_time')
      pixel_info
    rescue StandardError => e
      Rails.logger.warn("Could not verify pixel access for #{pixel_id}: #{e.message}")
      nil
    end
  end

  def get_business_id_from_pixel
    begin
      # Get businesses the user has access to
      businesses = facebook_api.get_connections('me', 'businesses', fields: 'id,name')
      
      # Check each business for the pixel
      businesses.each do |business|
        if pixel_belongs_to_business?(business['id'])
          return business['id']
        end
      end

      # Fallback: try to get business from ad accounts
      get_business_from_ad_accounts
    rescue StandardError => e
      Rails.logger.error("Error getting business ID from pixel: #{e.message}")
      nil
    end
  end

  def pixel_belongs_to_business?(business_id)
    begin
      pixels = facebook_api.get_connections(business_id, 'owned_pixels', fields: 'id')
      pixels.any? { |p| p['id'] == pixel_id }
    rescue StandardError => e
      Rails.logger.warn("Could not check pixels for business #{business_id}: #{e.message}")
      false
    end
  end

  def get_business_from_ad_accounts
    begin
      # Get ad accounts and check which business they belong to
      ad_accounts = facebook_api.get_connections('me', 'adaccounts', fields: 'id,business')
      
      ad_accounts.each do |ad_account|
        # Check if this ad account has access to our pixel
        if ad_account_has_pixel?(ad_account['id']) && ad_account['business']
          return ad_account['business']['id']
        end
      end

      nil
    rescue StandardError => e
      Rails.logger.error("Error getting business from ad accounts: #{e.message}")
      nil
    end
  end

  def ad_account_has_pixel?(ad_account_id)
    begin
      pixels = facebook_api.get_connections(ad_account_id, 'adspixels', fields: 'id')
      pixels.any? { |p| p['id'] == pixel_id }
    rescue StandardError => e
      Rails.logger.warn("Could not check pixels for ad account #{ad_account_id}: #{e.message}")
      false
    end
  end

  def generate_system_user_token(business_id)
    begin
      # Create a system user for Conversions API
      system_user_params = {
        name: "Mooly Conversions API - #{Time.current.strftime('%Y%m%d_%H%M%S')}",
        role: 'ADMIN'
      }

      # Create system user
      system_user = facebook_api.put_connections(business_id, 'system_users', system_user_params)
      system_user_id = system_user['id']

      # Generate access token for the system user
      token_params = {
        scope: 'ads_management,business_management'
      }

      token_response = facebook_api.post("#{system_user_id}/access_tokens", token_params)
      
      if token_response['access_token']
        {
          success: true,
          access_token: token_response['access_token'],
          system_user_id: system_user_id
        }
      else
        { success: false, error: 'Failed to generate access token' }
      end
    rescue StandardError => e
      Rails.logger.error("Error generating system user token: #{e.message}")
      
      # Fallback: try to use existing user token with extended permissions
      try_extended_user_token
    end
  end

  def try_extended_user_token
    begin
      # Try to exchange for a long-lived token with ads_management permission
      oauth = Koala::Facebook::OAuth.new(
        GlobalConfigService.load('FB_APP_ID', ''),
        GlobalConfigService.load('FB_APP_SECRET', '')
      )
      
      # Exchange for long-lived token
      token_info = oauth.exchange_access_token_info(user_access_token)
      long_lived_token = token_info['access_token']
      
      if long_lived_token
        {
          success: true,
          access_token: long_lived_token,
          note: 'Using extended user access token. For production, consider using system user tokens.'
        }
      else
        { success: false, error: 'Could not generate any suitable access token' }
      end
    rescue StandardError => e
      Rails.logger.error("Error generating extended user token: #{e.message}")
      { success: false, error: 'Failed to generate access token. Please check your Facebook app configuration.' }
    end
  end
end
