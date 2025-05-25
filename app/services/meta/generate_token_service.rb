# Service to generate Facebook Conversions API access token for Meta platform
# Meta tokens work for both Facebook and Instagram
class Meta::GenerateTokenService
  attr_reader :account, :pixel_id

  def initialize(account:, pixel_id:)
    @account = account
    @pixel_id = pixel_id
  end

  # Generate a Conversions API access token for Meta platform
  def generate_conversions_api_token
    meta_channels = get_meta_channels
    return { success: false, error: 'No Meta channels found' } if meta_channels.empty?

    # Try each channel until we find one that works
    meta_channels.each do |channel|
      result = try_generate_token_for_channel(channel)
      return result if result[:success]
    end

    { success: false, error: 'Could not generate token through any Meta channel' }
  end

  private

  def get_meta_channels
    account.inboxes
           .joins(:channel)
           .where(channels: { type: 'Channel::FacebookPage' })
           .map(&:channel)
  end

  def try_generate_token_for_channel(channel)
    return { success: false, error: 'User access token not available' } unless channel.user_access_token.present?

    begin
      # Verify pixel access through this channel
      unless verify_pixel_access_through_channel(channel)
        return { success: false, error: 'Pixel not accessible through this Meta channel' }
      end

      # Get business ID from the channel
      business_id = get_business_id_for_channel(channel)
      return { success: false, error: 'Could not determine business account' } unless business_id

      # Generate system user token
      token_result = generate_system_user_token(channel, business_id)
      
      if token_result[:success]
        {
          success: true,
          access_token: token_result[:access_token],
          business_id: business_id,
          pixel_id: pixel_id,
          channel_id: channel.id,
          supports: ['facebook', 'instagram']
        }
      else
        token_result
      end
    rescue Koala::Facebook::AuthenticationError => e
      Rails.logger.error("Meta authentication error: #{e.message}")
      { success: false, error: 'Meta authentication failed. Please reconnect your account.' }
    rescue StandardError => e
      Rails.logger.error("Error generating token for Meta channel #{channel.id}: #{e.message}")
      { success: false, error: e.message }
    end
  end

  def verify_pixel_access_through_channel(channel)
    facebook_api = Koala::Facebook::API.new(channel.user_access_token)
    
    begin
      # Try to get pixel information
      pixel_info = facebook_api.get_object(pixel_id, fields: 'id,name')
      pixel_info.present?
    rescue StandardError => e
      Rails.logger.warn("Could not verify pixel access for channel #{channel.id}: #{e.message}")
      false
    end
  end

  def get_business_id_for_channel(channel)
    facebook_api = Koala::Facebook::API.new(channel.user_access_token)
    
    begin
      # Get businesses the user has access to
      businesses = facebook_api.get_connections('me', 'businesses', fields: 'id,name')
      
      # Check which business owns our pixel
      businesses.each do |business|
        if pixel_belongs_to_business?(facebook_api, business['id'])
          return business['id']
        end
      end

      # Fallback: get business from ad accounts
      get_business_from_ad_accounts(facebook_api)
    rescue StandardError => e
      Rails.logger.error("Error getting business ID for channel #{channel.id}: #{e.message}")
      nil
    end
  end

  def pixel_belongs_to_business?(facebook_api, business_id)
    begin
      pixels = facebook_api.get_connections(business_id, 'owned_pixels', fields: 'id')
      pixels.any? { |p| p['id'] == pixel_id }
    rescue StandardError => e
      Rails.logger.warn("Could not check pixels for business #{business_id}: #{e.message}")
      false
    end
  end

  def get_business_from_ad_accounts(facebook_api)
    begin
      ad_accounts = facebook_api.get_connections('me', 'adaccounts', fields: 'id,business')
      
      ad_accounts.each do |ad_account|
        if ad_account_has_pixel?(facebook_api, ad_account['id']) && ad_account['business']
          return ad_account['business']['id']
        end
      end

      nil
    rescue StandardError => e
      Rails.logger.error("Error getting business from ad accounts: #{e.message}")
      nil
    end
  end

  def ad_account_has_pixel?(facebook_api, ad_account_id)
    begin
      pixels = facebook_api.get_connections(ad_account_id, 'adspixels', fields: 'id')
      pixels.any? { |p| p['id'] == pixel_id }
    rescue StandardError => e
      Rails.logger.warn("Could not check pixels for ad account #{ad_account_id}: #{e.message}")
      false
    end
  end

  def generate_system_user_token(channel, business_id)
    facebook_api = Koala::Facebook::API.new(channel.user_access_token)
    
    begin
      # Create a system user for Meta Conversions API
      system_user_params = {
        name: "Mooly Meta Conversions API - #{Time.current.strftime('%Y%m%d_%H%M%S')}",
        role: 'ADMIN'
      }

      # Create system user
      system_user = facebook_api.put_connections(business_id, 'system_users', system_user_params)
      system_user_id = system_user['id']

      # Generate access token for the system user with comprehensive permissions
      token_params = {
        scope: 'ads_management,business_management,pages_messaging,instagram_basic,instagram_manage_messages,pages_show_list,pages_read_engagement'
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
      
      # Fallback: try to use extended user token
      try_extended_user_token(channel)
    end
  end

  def try_extended_user_token(channel)
    begin
      oauth = Koala::Facebook::OAuth.new(
        GlobalConfigService.load('FB_APP_ID', ''),
        GlobalConfigService.load('FB_APP_SECRET', '')
      )
      
      # Exchange for long-lived token
      token_info = oauth.exchange_access_token_info(channel.user_access_token)
      long_lived_token = token_info['access_token']
      
      if long_lived_token
        {
          success: true,
          access_token: long_lived_token,
          note: 'Using extended user access token for Meta. For production, consider using system user tokens.'
        }
      else
        { success: false, error: 'Could not generate any suitable access token for Meta' }
      end
    rescue StandardError => e
      Rails.logger.error("Error generating extended user token for Meta: #{e.message}")
      { success: false, error: 'Failed to generate access token. Please check your Meta app configuration.' }
    end
  end
end
