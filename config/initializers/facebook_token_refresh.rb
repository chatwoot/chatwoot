# Facebook Token Refresh Scheduler
# This initializer sets up periodic token refresh for Facebook channels

Rails.application.configure do
  # Schedule Facebook token refresh job to run every 6 hours
  # This helps ensure tokens are refreshed before they expire
  config.after_initialize do
    if Rails.env.production? || Rails.env.staging?
      # In production, use a background job scheduler like sidekiq-cron or whenever gem
      # For now, we'll use a simple approach with delayed_job or sidekiq
      
      # Schedule the job to run every 6 hours
      # You can adjust this interval based on your needs
      Rails.logger.info("Setting up Facebook token refresh scheduler")
      
      # If using sidekiq-cron, you would add this to your schedule:
      # Sidekiq::Cron::Job.create(
      #   name: 'Facebook Token Refresh',
      #   cron: '0 */6 * * *', # Every 6 hours
      #   class: 'FacebookTokenRefreshJob'
      # )
      
      # For now, we'll just log that the scheduler is available
      Rails.logger.info("Facebook token refresh job available: FacebookTokenRefreshJob")
      Rails.logger.info("To schedule this job, use your preferred job scheduler (sidekiq-cron, whenever, etc.)")
      Rails.logger.info("Recommended schedule: every 6 hours (0 */6 * * *)")
    end
  end
end

# Manual token refresh trigger
# You can call this method to manually trigger token refresh for all Facebook channels
def refresh_all_facebook_tokens
  FacebookTokenRefreshJob.perform_later
end

# Check specific channel token
def check_facebook_token(channel_id)
  channel = Channel::FacebookPage.find(channel_id)
  refresh_service = Facebook::RefreshOauthTokenService.new(channel: channel)
  
  {
    channel_id: channel_id,
    page_id: channel.page_id,
    token_valid: refresh_service.token_valid?,
    reauthorization_required: channel.reauthorization_required?
  }
rescue StandardError => e
  {
    channel_id: channel_id,
    error: e.message
  }
end
