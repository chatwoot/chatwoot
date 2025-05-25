# Service to handle Facebook access token refresh logic
# Facebook page access tokens can be refreshed using the user access token
# This service implements the refresh logic per official Facebook API guidelines
class Facebook::RefreshOauthTokenService
  attr_reader :channel

  def initialize(channel:)
    @channel = channel
  end

  # Returns a valid access token, refreshing it if necessary and eligible
  def access_token
    return channel.page_access_token unless token_needs_refresh?

    attempt_token_refresh
  end

  # Check if the current token is valid by making a test API call
  def token_valid?
    return false if channel.page_access_token.blank?

    begin
      api = Koala::Facebook::API.new(channel.page_access_token)
      # Test the token by getting page info
      api.get_object(channel.page_id, fields: 'id,name')
      true
    rescue Koala::Facebook::AuthenticationError, Koala::Facebook::ClientError => e
      Rails.logger.warn("Facebook token validation failed for page #{channel.page_id}: #{e.message}")
      false
    rescue StandardError => e
      Rails.logger.error("Unexpected error during Facebook token validation: #{e.message}")
      false
    end
  end

  # Check if token needs refresh (invalid or will expire soon)
  def token_needs_refresh?
    !token_valid?
  end

  # Refresh the page access token using the user access token
  def refresh_page_access_token
    return nil if channel.user_access_token.blank?

    begin
      # Use user access token to get fresh page access token
      api = Koala::Facebook::API.new(channel.user_access_token)
      pages = api.get_connections('me', 'accounts')
      
      # Find the specific page
      page_data = pages.find { |page| page['id'] == channel.page_id }
      
      if page_data && page_data['access_token']
        Rails.logger.info("Successfully refreshed Facebook page access token for page #{channel.page_id}")
        return page_data['access_token']
      else
        Rails.logger.warn("Could not find page #{channel.page_id} in user's pages during token refresh")
        return nil
      end
    rescue Koala::Facebook::AuthenticationError => e
      Rails.logger.error("Facebook user token authentication failed during refresh: #{e.message}")
      # User token is also invalid, need full reauthorization
      channel.authorization_error!
      return nil
    rescue StandardError => e
      Rails.logger.error("Error refreshing Facebook page access token: #{e.message}")
      return nil
    end
  end

  # Update channel with new tokens
  def update_channel_tokens(new_page_token, new_user_token = nil)
    update_params = { page_access_token: new_page_token }
    update_params[:user_access_token] = new_user_token if new_user_token.present?
    
    channel.update!(update_params)
    Rails.logger.info("Updated Facebook tokens for page #{channel.page_id}")
  end

  # Attempts to refresh the token, returning either the new or existing token
  def attempt_token_refresh
    new_page_token = refresh_page_access_token
    
    if new_page_token.present?
      update_channel_tokens(new_page_token)
      # Clear any existing authorization errors since refresh was successful
      channel.reauthorized! if channel.reauthorization_required?
      channel.reload.page_access_token
    else
      Rails.logger.error("Failed to refresh Facebook token for page #{channel.page_id}")
      # Mark for reauthorization if not already marked
      channel.authorization_error! unless channel.reauthorization_required?
      channel.page_access_token
    end
  rescue StandardError => e
    Rails.logger.error("Token refresh failed for page #{channel.page_id}: #{e.message}")
    channel.authorization_error! unless channel.reauthorization_required?
    channel.page_access_token
  end

  # Refresh user access token to long-lived token if needed
  def refresh_user_access_token
    return nil if channel.user_access_token.blank?

    begin
      oauth = Koala::Facebook::OAuth.new(
        GlobalConfigService.load('FB_APP_ID', ''),
        GlobalConfigService.load('FB_APP_SECRET', '')
      )
      
      # Exchange for long-lived token
      token_info = oauth.exchange_access_token_info(channel.user_access_token)
      new_user_token = token_info['access_token']
      
      if new_user_token.present?
        Rails.logger.info("Successfully refreshed Facebook user access token")
        return new_user_token
      else
        Rails.logger.warn("Failed to get new user access token from Facebook")
        return nil
      end
    rescue StandardError => e
      Rails.logger.error("Error refreshing Facebook user access token: #{e.message}")
      return nil
    end
  end

  # Full refresh: both user and page tokens
  def full_token_refresh
    new_user_token = refresh_user_access_token
    
    if new_user_token.present?
      # Update user token first
      channel.update!(user_access_token: new_user_token)
      
      # Then refresh page token using new user token
      new_page_token = refresh_page_access_token
      
      if new_page_token.present?
        update_channel_tokens(new_page_token, new_user_token)
        channel.reauthorized! if channel.reauthorization_required?
        return { success: true, page_token: new_page_token, user_token: new_user_token }
      end
    end
    
    # If we get here, refresh failed
    channel.authorization_error! unless channel.reauthorization_required?
    { success: false, error: 'Token refresh failed' }
  end
end
