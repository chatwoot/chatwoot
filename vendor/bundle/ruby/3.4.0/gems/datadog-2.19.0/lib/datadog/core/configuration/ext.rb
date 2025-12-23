# frozen_string_literal: true

module Datadog
  module Core
    module Configuration
      # Constants for configuration settings
      # e.g. Env vars, default values, enums, etc...
      module Ext
        # @public_api
        module Diagnostics
          ENV_DEBUG_ENABLED = 'DD_TRACE_DEBUG'
          ENV_OTEL_LOG_LEVEL = 'OTEL_LOG_LEVEL'
          ENV_HEALTH_METRICS_ENABLED = 'DD_HEALTH_METRICS_ENABLED'
          ENV_STARTUP_LOGS_ENABLED = 'DD_TRACE_STARTUP_LOGS'
        end

        module Metrics
          ENV_DEFAULT_PORT = 'DD_METRIC_AGENT_PORT'
        end

        module APM
          ENV_TRACING_ENABLED = 'DD_APM_TRACING_ENABLED'
        end

        module Agent
          ENV_DEFAULT_HOST = 'DD_AGENT_HOST'
          # Some env vars have "trace" in them, but they apply to all products
          ENV_DEFAULT_PORT = 'DD_TRACE_AGENT_PORT'
          ENV_DEFAULT_TIMEOUT_SECONDS = 'DD_TRACE_AGENT_TIMEOUT_SECONDS'
          ENV_DEFAULT_URL = 'DD_TRACE_AGENT_URL'

          module HTTP
            ADAPTER = :net_http
            DEFAULT_HOST = '127.0.0.1'
            DEFAULT_PORT = 8126
            DEFAULT_USE_SSL = false
            DEFAULT_TIMEOUT_SECONDS = 30
          end

          # @public_api
          module UnixSocket
            ADAPTER = :unix
            DEFAULT_PATH = '/var/run/datadog/apm.socket'
            DEFAULT_TIMEOUT_SECONDS = 30
          end
        end
      end
    end
  end
end
