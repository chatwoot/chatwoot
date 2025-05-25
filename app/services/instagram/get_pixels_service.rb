# Service to fetch Facebook Pixels accessible to Instagram Business accounts
# Instagram uses the same Facebook Pixel infrastructure
class Instagram::GetPixelsService
  attr_reader :account

  def initialize(account:)
    @account = account
  end

  # Get all pixels accessible to Instagram Business accounts
  def get_pixels
    instagram_channels = get_instagram_channels
    return { success: false, error: 'No Instagram channels found' } if instagram_channels.empty?

    begin
      all_pixels = []
      
      instagram_channels.each do |channel|
        channel_pixels = get_pixels_for_channel(channel)
        all_pixels.concat(channel_pixels)
      end

      # Remove duplicates and format
      unique_pixels = all_pixels.uniq { |p| p['id'] }
      formatted_pixels = format_pixels(unique_pixels)

      {
        success: true,
        pixels: formatted_pixels,
        count: formatted_pixels.length
      }
    rescue Koala::Facebook::AuthenticationError => e
      Rails.logger.error("Instagram authentication error in GetPixelsService: #{e.message}")
      { success: false, error: 'Instagram authentication failed. Please reconnect your Instagram account.' }
    rescue Koala::Facebook::ClientError => e
      Rails.logger.error("Instagram client error in GetPixelsService: #{e.message}")
      { success: false, error: 'Instagram API error. Please check your permissions.' }
    rescue StandardError => e
      Rails.logger.error("Error in Instagram GetPixelsService: #{e.message}")
      { success: false, error: 'Failed to fetch pixels. Please try again.' }
    end
  end

  private

  def get_instagram_channels
    account.inboxes
           .joins(:channel)
           .where(channels: { type: 'Channel::FacebookPage' })
           .where.not(channels: { instagram_id: [nil, ''] })
           .map(&:channel)
  end

  def get_pixels_for_channel(channel)
    return [] unless channel.user_access_token.present?

    facebook_api = Koala::Facebook::API.new(channel.user_access_token)
    
    # Get Instagram Business Account
    instagram_account = get_instagram_business_account(facebook_api, channel.instagram_id)
    return [] unless instagram_account

    # Get pixels through connected Facebook Page
    get_pixels_through_facebook_page(facebook_api, channel.page_id)
  end

  def get_instagram_business_account(facebook_api, instagram_id)
    begin
      instagram_account = facebook_api.get_object(instagram_id, fields: 'id,name,username')
      instagram_account
    rescue StandardError => e
      Rails.logger.warn("Could not get Instagram Business Account #{instagram_id}: #{e.message}")
      nil
    end
  end

  def get_pixels_through_facebook_page(facebook_api, page_id)
    begin
      # Get the Facebook Page
      page = facebook_api.get_object(page_id, fields: 'id,name')
      
      # Get business accounts associated with the page
      businesses = facebook_api.get_connections(page_id, 'businesses', fields: 'id,name')
      
      pixels = []
      businesses.each do |business|
        business_pixels = get_pixels_from_business(facebook_api, business['id'])
        pixels.concat(business_pixels)
      end

      # Fallback: try to get pixels from ad accounts
      if pixels.empty?
        pixels = get_pixels_from_ad_accounts(facebook_api)
      end

      pixels
    rescue StandardError => e
      Rails.logger.warn("Could not get pixels through Facebook page #{page_id}: #{e.message}")
      []
    end
  end

  def get_pixels_from_business(facebook_api, business_id)
    begin
      pixels = facebook_api.get_connections(business_id, 'owned_pixels', fields: 'id,name,creation_time')
      pixels || []
    rescue StandardError => e
      Rails.logger.warn("Could not fetch pixels from business #{business_id}: #{e.message}")
      []
    end
  end

  def get_pixels_from_ad_accounts(facebook_api)
    begin
      ad_accounts = facebook_api.get_connections('me', 'adaccounts', fields: 'id,name')
      
      pixels = []
      ad_accounts.each do |ad_account|
        account_pixels = facebook_api.get_connections(ad_account['id'], 'adspixels', fields: 'id,name,creation_time')
        pixels.concat(account_pixels || [])
      end

      pixels
    rescue StandardError => e
      Rails.logger.warn("Could not get pixels from ad accounts: #{e.message}")
      []
    end
  end

  def format_pixels(pixels)
    pixels.map do |pixel|
      {
        id: pixel['id'],
        name: pixel['name'] || "Pixel #{pixel['id']}",
        creation_time: pixel['creation_time'],
        formatted_name: format_pixel_name(pixel),
        platform: 'instagram'
      }
    end.sort_by { |p| p[:name] }
  end

  def format_pixel_name(pixel)
    name = pixel['name'] || "Pixel #{pixel['id']}"
    creation_date = pixel['creation_time'] ? Date.parse(pixel['creation_time']).strftime('%Y-%m-%d') : ''
    
    base_name = "#{name} (Instagram)"
    if creation_date.present?
      "#{base_name} - Created: #{creation_date}"
    else
      base_name
    end
  end
end
