# frozen_string_literal: true

# SocialWise Cache Initialization
# Preloads WhatsApp inbox cache for better webhook performance

Rails.application.config.to_prepare do
  # Skip during assets precompilation or when database is not available
  next if defined?(Rails::Console) && Rails.const_defined?('Console')
  next if Rails.env.test?
  next if ENV['SKIP_SOCIALWISE_CACHE'] == 'true'
  
  # Only preload cache in production and staging environments
  # Skip in development and during migrations/seeds
  if Rails.env.production? || Rails.env.staging?
    begin
      # Skip during database migrations or when database is not ready
      next unless ActiveRecord::Base.connection.table_exists?('inboxes')
      next unless ActiveRecord::Base.connection.table_exists?('channels')
      
      # Preload cache in a background thread to not block application startup
      Thread.new do
        begin
          Rails.logger.info "[SOCIALWISE] Starting cache preload in background thread"
          
          # Wait a bit for the application to fully initialize
          sleep(5)
          
          # Preload WhatsApp inbox cache
          Integrations::Socialwise::WebhookEnhancerService.preload_whatsapp_inbox_cache
          
          Rails.logger.info "[SOCIALWISE] Cache preload completed successfully"
        rescue => e
          Rails.logger.error "[SOCIALWISE] Cache preload failed: #{e.message}"
          Rails.logger.error "[SOCIALWISE] Backtrace: #{e.backtrace.join('\n')}"
        end
      end
    rescue ActiveRecord::ConnectionNotEstablished
      # Ignore connection errors during build/precompile
      Rails.logger.info "[SOCIALWISE] Skipping cache preload - database not available"
    rescue => e
      # Ignore other database-related errors during build
      Rails.logger.info "[SOCIALWISE] Skipping cache preload due to error: #{e.message}"
    end
  else
    Rails.logger.info "[SOCIALWISE] Skipping cache preload in #{Rails.env} environment"
  end
end