# Service to fetch Facebook Pixels that can be shared between Facebook and Instagram
# Meta platform allows unified pixel management across both platforms
class Meta::GetPixelsService
  attr_reader :account

  def initialize(account:)
    @account = account
  end

  # Get all pixels accessible to Meta (Facebook/Instagram) channels
  def get_pixels
    meta_channels = get_meta_channels
    return { success: false, error: 'No Meta channels found' } if meta_channels.empty?

    begin
      all_pixels = []
      
      meta_channels.each do |channel|
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
      Rails.logger.error("Meta authentication error in GetPixelsService: #{e.message}")
      { success: false, error: 'Meta authentication failed. Please reconnect your Facebook account.' }
    rescue Koala::Facebook::ClientError => e
      Rails.logger.error("Meta client error in GetPixelsService: #{e.message}")
      { success: false, error: 'Meta API error. Please check your permissions.' }
    rescue StandardError => e
      Rails.logger.error("Error in Meta GetPixelsService: #{e.message}")
      { success: false, error: 'Failed to fetch pixels. Please try again.' }
    end
  end

  private

  def get_meta_channels
    # Get all Facebook channels (both with and without Instagram)
    account.inboxes
           .joins(:channel)
           .where(channels: { type: 'Channel::FacebookPage' })
           .map(&:channel)
  end

  def get_pixels_for_channel(channel)
    return [] unless channel.user_access_token.present?

    facebook_api = Koala::Facebook::API.new(channel.user_access_token)
    
    pixels = []
    
    # Get pixels from business accounts
    business_pixels = get_pixels_from_businesses(facebook_api)
    pixels.concat(business_pixels)
    
    # Get pixels from ad accounts as fallback
    if pixels.empty?
      ad_account_pixels = get_pixels_from_ad_accounts(facebook_api)
      pixels.concat(ad_account_pixels)
    end

    pixels
  end

  def get_pixels_from_businesses(facebook_api)
    begin
      businesses = facebook_api.get_connections('me', 'businesses', fields: 'id,name')
      
      pixels = []
      businesses.each do |business|
        business_pixels = get_pixels_from_business(facebook_api, business['id'])
        pixels.concat(business_pixels)
      end

      pixels
    rescue StandardError => e
      Rails.logger.warn("Could not get pixels from businesses: #{e.message}")
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
        platform: 'meta',
        supports: ['facebook', 'instagram']
      }
    end.sort_by { |p| p[:name] }
  end

  def format_pixel_name(pixel)
    name = pixel['name'] || "Pixel #{pixel['id']}"
    creation_date = pixel['creation_time'] ? Date.parse(pixel['creation_time']).strftime('%Y-%m-%d') : ''
    
    base_name = "#{name} (Meta - FB/IG)"
    if creation_date.present?
      "#{base_name} - Created: #{creation_date}"
    else
      base_name
    end
  end
end
