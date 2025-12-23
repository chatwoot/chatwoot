# frozen_string_literal: true

require 'json'
require 'rbconfig'
require 'time'

module Datadog
  module Core
    module Diagnostics
      # Base class for EnvironmentLoggers - should allow for easy reporting by users to Datadog support.
      #
      # The EnvironmentLogger should not pollute the logs in a development environment.
      module EnvironmentLogging
        def log_configuration!(prefix, data)
          logger.info("DATADOG CONFIGURATION - #{prefix} - #{data}")
        end

        def log_debug!(prefix, data)
          logger.debug("DATADOG CONFIGURATION - #{prefix} - #{data}")
        end

        def log_error!(prefix, type, error)
          logger.warn("DATADOG ERROR - #{prefix} - #{type}: #{error}")
        end

        protected

        def logger
          Datadog.logger
        end

        # Are we logging the environment data?
        def log?
          startup_logs_enabled = Datadog.configuration.diagnostics.startup_logs.enabled
          if startup_logs_enabled.nil?
            # Do not pollute the logs in a development environment.
            !Datadog::Core::Environment::Execution.development?
          else
            startup_logs_enabled
          end
        end
      end

      # Collects and logs Core diagnostic information
      module EnvironmentLogger
        extend EnvironmentLogging

        def self.collect_and_log!(extra_fields = nil)
          if log?
            data = EnvironmentCollector.collect_config!
            data = data.merge(extra_fields) if extra_fields
            log_configuration!('CORE', data.to_json)
          end
        rescue => e
          logger.warn("Failed to collect core environment information: #{e} Location: #{Array(e.backtrace).first}")
        end
      end

      # Collects environment information for Core diagnostic logging
      module EnvironmentCollector
        class << self
          def collect_config!
            {
              date: date,
              os_name: os_name,
              version: version,
              lang: lang,
              lang_version: lang_version,
              env: env,
              service: service,
              dd_version: dd_version,
              debug: debug,
              tags: tags,
              runtime_metrics_enabled: runtime_metrics_enabled,
              vm: vm,
              health_metrics_enabled: health_metrics_enabled
            }
          end

          # @return [String] current time in ISO8601 format
          def date
            Core::Utils::Time.now.utc.iso8601
          end

          # Best portable guess of OS information.
          # @return [String] platform string
          def os_name
            RbConfig::CONFIG['host']
          end

          # @return [String] datadog version
          def version
            Datadog::VERSION::STRING
          end

          # @return [String] "ruby"
          def lang
            Core::Environment::Ext::LANG
          end

          # Supported Ruby language version.
          # Will be distinct from VM version for non-MRI environments.
          # @return [String]
          def lang_version
            Core::Environment::Ext::LANG_VERSION
          end

          # @return [String] configured application environment
          def env
            Datadog.configuration.env
          end

          # @return [String] configured application service name
          def service
            Datadog.configuration.service
          end

          # @return [String] configured application version
          def dd_version
            Datadog.configuration.version
          end

          # @return [Boolean, nil] debug mode enabled in configuration
          def debug
            !!Datadog.configuration.diagnostics.debug
          end

          # @return [Hash, nil] concatenated list of global tracer tags configured
          def tags
            tags = Datadog.configuration.tags
            return nil if tags.empty?

            hash_serializer(tags)
          end

          # @return [Boolean, nil] runtime metrics enabled in configuration
          def runtime_metrics_enabled
            Datadog.configuration.runtime_metrics.enabled
          end

          # Ruby VM name and version.
          # Examples: "ruby-2.7.1", "jruby-9.2.11.1", "truffleruby-20.1.0"
          # @return [String, nil]
          def vm
            # RUBY_ENGINE_VERSION returns the VM version, which
            # will differ from RUBY_VERSION for non-mri VMs.
            if defined?(RUBY_ENGINE_VERSION)
              "#{RUBY_ENGINE}-#{RUBY_ENGINE_VERSION}"
            else
              # Ruby < 2.3 doesn't support RUBY_ENGINE_VERSION
              "#{RUBY_ENGINE}-#{RUBY_VERSION}"
            end
          end

          # @return [Boolean, nil] health metrics enabled in configuration
          def health_metrics_enabled
            !!Datadog.configuration.health_metrics.enabled
          end

          private

          # Outputs "k1:v1,k2:v2,..."
          def hash_serializer(h)
            h.map { |k, v| "#{k}:#{v}" }.join(',')
          end
        end
      end
    end
  end
end
