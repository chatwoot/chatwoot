# Service to fetch Facebook Pixels from Business Manager
# Uses the existing Facebook OAuth connection to get available pixels
class Facebook::GetPixelsService
  attr_reader :channel

  def initialize(channel:)
    @channel = channel
  end

  # Get all pixels accessible to the current Facebook user
  def get_pixels
    return { success: false, error: 'Facebook channel not configured' } unless channel.is_a?(Channel::FacebookPage)
    return { success: false, error: 'Facebook access token not available' } unless access_token.present?

    begin
      # Get business accounts first
      business_accounts = get_business_accounts
      
      if business_accounts.empty?
        # Fallback: try to get pixels directly from ad accounts
        return get_pixels_from_ad_accounts
      end

      # Get pixels from business accounts
      pixels = []
      business_accounts.each do |business|
        business_pixels = get_pixels_from_business(business['id'])
        pixels.concat(business_pixels)
      end

      # Remove duplicates and format
      unique_pixels = pixels.uniq { |p| p['id'] }
      formatted_pixels = format_pixels(unique_pixels)

      {
        success: true,
        pixels: formatted_pixels,
        count: formatted_pixels.length
      }
    rescue Koala::Facebook::AuthenticationError => e
      Rails.logger.error("Facebook authentication error in GetPixelsService: #{e.message}")
      { success: false, error: 'Facebook authentication failed. Please reconnect your Facebook account.' }
    rescue Koala::Facebook::ClientError => e
      Rails.logger.error("Facebook client error in GetPixelsService: #{e.message}")
      { success: false, error: 'Facebook API error. Please check your permissions.' }
    rescue StandardError => e
      Rails.logger.error("Error in GetPixelsService: #{e.message}")
      { success: false, error: 'Failed to fetch pixels. Please try again.' }
    end
  end

  private

  def access_token
    @access_token ||= channel.user_access_token || channel.page_access_token
  end

  def facebook_api
    @facebook_api ||= Koala::Facebook::API.new(access_token)
  end

  def get_business_accounts
    begin
      # Get businesses the user has access to
      businesses = facebook_api.get_connections('me', 'businesses', fields: 'id,name')
      businesses || []
    rescue StandardError => e
      Rails.logger.warn("Could not fetch business accounts: #{e.message}")
      []
    end
  end

  def get_pixels_from_business(business_id)
    begin
      # Get pixels owned by the business
      pixels = facebook_api.get_connections(business_id, 'owned_pixels', fields: 'id,name,creation_time')
      pixels || []
    rescue StandardError => e
      Rails.logger.warn("Could not fetch pixels from business #{business_id}: #{e.message}")
      []
    end
  end

  def get_pixels_from_ad_accounts
    begin
      # Get ad accounts the user has access to
      ad_accounts = facebook_api.get_connections('me', 'adaccounts', fields: 'id,name')
      
      pixels = []
      ad_accounts.each do |ad_account|
        account_pixels = get_pixels_from_ad_account(ad_account['id'])
        pixels.concat(account_pixels)
      end

      unique_pixels = pixels.uniq { |p| p['id'] }
      formatted_pixels = format_pixels(unique_pixels)

      {
        success: true,
        pixels: formatted_pixels,
        count: formatted_pixels.length
      }
    rescue StandardError => e
      Rails.logger.error("Error getting pixels from ad accounts: #{e.message}")
      { success: false, error: 'Could not access ad accounts. Please check your permissions.' }
    end
  end

  def get_pixels_from_ad_account(ad_account_id)
    begin
      # Get pixels associated with the ad account
      pixels = facebook_api.get_connections(ad_account_id, 'adspixels', fields: 'id,name,creation_time')
      pixels || []
    rescue StandardError => e
      Rails.logger.warn("Could not fetch pixels from ad account #{ad_account_id}: #{e.message}")
      []
    end
  end

  def format_pixels(pixels)
    pixels.map do |pixel|
      {
        id: pixel['id'],
        name: pixel['name'] || "Pixel #{pixel['id']}",
        creation_time: pixel['creation_time'],
        formatted_name: format_pixel_name(pixel)
      }
    end.sort_by { |p| p[:name] }
  end

  def format_pixel_name(pixel)
    name = pixel['name'] || "Pixel #{pixel['id']}"
    creation_date = pixel['creation_time'] ? Date.parse(pixel['creation_time']).strftime('%Y-%m-%d') : ''
    
    if creation_date.present?
      "#{name} (Created: #{creation_date})"
    else
      name
    end
  end
end
