if ENV['SENTRY_DSN']
  Sentry.init do |config|
    config.dsn = ENV.fetch('SENTRY_DSN', nil)
    config.enabled_environments = %w[staging production]
  end
end
