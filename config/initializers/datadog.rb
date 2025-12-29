# frozen_string_literal: true

# Datadog APM Configuration (Agentless Mode)
# This configuration sends traces directly to Datadog's API without requiring a local agent
# Requires: DD_API_KEY, DD_SITE (optional, defaults to datadoghq.com)

if ENV['DD_API_KEY'].present?
  begin
    require 'datadog/appsec'

    Datadog.configure do |c|
      # Service configuration
      c.service = ENV.fetch('DD_SERVICE', 'merkurwoot')
      c.env = ENV.fetch('DD_ENV', Rails.env)
      
      # Read version from VERSION_CW file if available
      version_file = Rails.root.join('VERSION_CW')
      c.version = ENV.fetch('DD_VERSION', File.read(version_file).strip) if version_file.exist?

      # Agentless configuration - send traces directly to Datadog API
      # Format: https://trace.agent.{{site}}
      dd_site = ENV.fetch('DD_SITE', 'datadoghq.com')
      c.tracing.transport_options = lambda { |t|
        t.adapter :net_http, "https://trace.agent.#{dd_site}"
      }

      # Global tags - useful for filtering and grouping in Datadog
      c.tags = {
        'team' => 'backend',
        'project' => 'merkurwoot'
      }

      # APM Instrumentation
      # Rails instrumentation (controllers, views, ActiveRecord, ActionCable, etc.)
      c.tracing.instrument :rails, {
        service_name: "#{c.service}-rails",
        analytics_enabled: true,
        distributed_tracing: true,
        # Track database queries
        database_service: "#{c.service}-postgres",
        # Track cache operations
        cache_service: "#{c.service}-cache",
        # Track template rendering
        template_base_path: 'app/views'
      }

      # Sidekiq instrumentation for background jobs
      c.tracing.instrument :sidekiq, {
        service_name: "#{c.service}-sidekiq",
        analytics_enabled: true,
        # Tag with job class and queue name
        tag_args: true
      }

      # Redis instrumentation
      c.tracing.instrument :redis, {
        service_name: "#{c.service}-redis",
        # Limit command arguments to avoid sending sensitive data
        command_args: false
      }

      # PostgreSQL/ActiveRecord instrumentation
      c.tracing.instrument :pg, {
        service_name: "#{c.service}-postgres",
        # Obfuscate SQL queries to remove sensitive data
        obfuscate_sql_values: true
      }

      # HTTP client instrumentation
      # RestClient (used in the app for external API calls)
      c.tracing.instrument :rest_client, {
        service_name: "#{c.service}-http-client",
        distributed_tracing: true,
        split_by_domain: true # Create separate services per domain
      }

      # Faraday (used by slack-ruby-client and other gems)
      c.tracing.instrument :faraday, {
        service_name: "#{c.service}-http-client",
        distributed_tracing: true,
        split_by_domain: true
      }

      # ActionCable instrumentation for WebSocket connections
      c.tracing.instrument :action_cable, {
        service_name: "#{c.service}-actioncable"
      }

      # Rack instrumentation for middleware
      c.tracing.instrument :rack, {
        service_name: "#{c.service}-web",
        distributed_tracing: true,
        # Track request queue time
        request_queuing: true
      }

      # Sampling configuration
      # Sample 100% of traces in development, adjust for production
      if Rails.env.production?
        # Sample rate: 1.0 = 100%, 0.1 = 10%
        # Adjust based on traffic volume and Datadog plan
        c.tracing.sampling.default_rate = ENV.fetch('DD_TRACE_SAMPLE_RATE', 1.0).to_f
      else
        c.tracing.sampling.default_rate = 1.0
      end

      # Logging
      # Send Datadog logs to Rails logger
      c.logger.instance = Rails.logger
      c.logger.level = Rails.env.production? ? ::Logger::INFO : ::Logger::DEBUG

      # Diagnostics - enable for troubleshooting
      c.diagnostics.debug = ENV.fetch('DD_TRACE_DEBUG', false) == 'true'

      # Runtime metrics - collect Ruby VM metrics
      c.runtime_metrics.enabled = true
      c.runtime_metrics.statsd = nil # Not using StatsD in agentless mode
    end

    Rails.logger.info "Datadog APM initialized in agentless mode (service: #{Datadog.configuration.service}, env: #{Datadog.configuration.env})"
  rescue StandardError => e
    Rails.logger.error "Failed to initialize Datadog APM: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end
