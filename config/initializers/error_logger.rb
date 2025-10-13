# config/initializers/error_logger.rb
require Rails.root.join('lib/error_logger')

Rails.logger.extend(ErrorLogger)

# Optional: if Chatwoot uses Sidekiq
if defined?(Sidekiq)
  Sidekiq.logger.extend(ErrorLogger)
end

ActiveSupport::LogSubscriber.logger&.extend(ErrorLogger)
