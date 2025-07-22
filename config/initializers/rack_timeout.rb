# Only load rack-timeout in production
if Rails.env.production?
  require 'rack-timeout'

  # Reduce noise by filtering state=ready and state=completed which are logged at INFO level
  Rails.application.config.after_initialize do
    Rack::Timeout::Logger.level = Logger::ERROR
  end
end
