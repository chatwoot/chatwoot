require "sidekiq"
require "sentry-ruby"
require "sentry/integrable"
require "sentry/sidekiq/version"
require "sentry/sidekiq/configuration"
require "sentry/sidekiq/error_handler"
require "sentry/sidekiq/sentry_context_middleware"

module Sentry
  module Sidekiq
    extend Sentry::Integrable

    register_integration name: "sidekiq", version: Sentry::Sidekiq::VERSION

    if defined?(::Rails::Railtie)
      class Railtie < ::Rails::Railtie
        config.after_initialize do
          next unless Sentry.initialized? && defined?(::Sentry::Rails)

          Sentry.configuration.rails.skippable_job_adapters << "ActiveJob::QueueAdapters::SidekiqAdapter"
        end
      end
    end
  end
end

Sidekiq.configure_server do |config|
  config.error_handlers << Sentry::Sidekiq::ErrorHandler.new
  config.server_middleware do |chain|
    chain.add Sentry::Sidekiq::SentryContextServerMiddleware
  end
  config.client_middleware do |chain|
    chain.add Sentry::Sidekiq::SentryContextClientMiddleware
  end
end

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add Sentry::Sidekiq::SentryContextClientMiddleware
  end
end

# patches
require "sentry/sidekiq/cron/job"
require "sentry/sidekiq-scheduler/scheduler"
