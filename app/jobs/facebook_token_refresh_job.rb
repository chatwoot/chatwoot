# Job to periodically check and refresh Facebook tokens
# This job runs regularly to ensure Facebook tokens are valid and refresh them if needed
class FacebookTokenRefreshJob < ApplicationJob
  queue_as :low

  # Run this job every 6 hours to check token health
  def perform
    Rails.logger.info("Starting Facebook token refresh job")
    
    facebook_channels = Channel::FacebookPage.joins(:inbox)
                                           .where(inboxes: { account: Account.active })
    
    facebook_channels.find_each do |channel|
      process_channel_token_refresh(channel)
    end
    
    Rails.logger.info("Completed Facebook token refresh job")
  end

  private

  def process_channel_token_refresh(channel)
    Rails.logger.info("Checking Facebook token for page #{channel.page_id}")
    
    refresh_service = Facebook::RefreshOauthTokenService.new(channel: channel)
    
    # Check if token is valid
    unless refresh_service.token_valid?
      Rails.logger.warn("Invalid Facebook token detected for page #{channel.page_id}, attempting refresh")
      
      # Attempt to refresh the token
      result = refresh_service.attempt_token_refresh
      
      if refresh_service.token_valid?
        Rails.logger.info("Successfully refreshed Facebook token for page #{channel.page_id}")
        
        # Send notification email about successful refresh
        send_token_refresh_notification(channel, :success)
      else
        Rails.logger.error("Failed to refresh Facebook token for page #{channel.page_id}")
        
        # Send notification email about failed refresh requiring manual intervention
        send_token_refresh_notification(channel, :failed)
      end
    else
      Rails.logger.debug("Facebook token is valid for page #{channel.page_id}")
    end
  rescue StandardError => e
    Rails.logger.error("Error processing Facebook token refresh for page #{channel.page_id}: #{e.message}")
    ChatwootExceptionTracker.new(e, account: channel.account).capture_exception
  end

  def send_token_refresh_notification(channel, status)
    return unless channel.inbox.present?

    case status
    when :success
      # Token was successfully refreshed automatically
      Rails.logger.info("Facebook token automatically refreshed for inbox #{channel.inbox.name}")
    when :failed
      # Token refresh failed, manual reauthorization required
      Rails.logger.warn("Facebook token refresh failed for inbox #{channel.inbox.name}, manual reauthorization required")
      
      # Send email notification to account administrators
      AdministratorNotifications::ChannelNotificationsMailer
        .with(account: channel.account)
        .facebook_disconnect(channel.inbox)
        .deliver_later
    end
  end
end
