Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.enabled_environments = %w[staging production]
end
