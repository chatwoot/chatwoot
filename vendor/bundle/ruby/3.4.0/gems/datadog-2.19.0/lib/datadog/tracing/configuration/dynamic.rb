# frozen_string_literal: true

require_relative 'dynamic/option'

module Datadog
  module Tracing
    module Configuration
      # Tracing Dynamic Configuration,
      # powered by the Remote Configuration platform.
      module Dynamic
        # Dynamic configuration for `DD_LOGS_INJECTION`.
        class LogInjectionEnabled < SimpleOption
          def initialize
            super('log_injection_enabled', 'DD_LOGS_INJECTION', :log_injection)
          end
        end

        # Dynamic configuration for `DD_TRACE_HEADER_TAGS`.
        class TracingHeaderTags < SimpleOption
          def initialize
            super('tracing_header_tags', 'DD_TRACE_HEADER_TAGS', :header_tags)
          end

          def call(tracing_header_tags)
            # Modify the remote configuration value that it matches the
            # environment variable it configures.
            if tracing_header_tags
              tracing_header_tags.map! do |hash|
                "#{hash['header']}:#{hash['tag_name']}"
              end
            end

            super(tracing_header_tags)
          end
        end

        # Dynamic configuration for `DD_TRACE_SAMPLE_RATE`.
        class TracingSamplingRate < SimpleOption
          def initialize
            super('tracing_sampling_rate', 'DD_TRACE_SAMPLE_RATE', :default_rate)
          end

          # Ensures sampler is rebuilt and new configuration is applied
          def call(tracing_sampling_rate)
            super
            Datadog.send(:components).reconfigure_live_sampler
          end

          protected

          def configuration_object
            Datadog.configuration.tracing.sampling
          end
        end

        # Dynamic configuration for `DD_TRACE_SAMPLING_RULES`.
        class TracingSamplingRules < SimpleOption
          def initialize
            super('tracing_sampling_rules', 'DD_TRACE_SAMPLING_RULES', :rules)
          end

          # Ensures sampler is rebuilt and new configuration is applied
          def call(tracing_sampling_rules)
            # Modify the remote configuration value that it matches the
            # local environment variable it configures.
            if tracing_sampling_rules
              tracing_sampling_rules.each do |rule|
                next unless (tags = rule['tags'])

                # Tag maps come in as arrays of 'key' and `value_glob`.
                # We need to convert them into a hash for local use.
                tag_array = tags.map! do |tag|
                  [tag['key'], tag['value_glob']]
                end

                rule['tags'] = tag_array.to_h
              end

              # The configuration is stored as JSON, so we need to convert it back
              tracing_sampling_rules = tracing_sampling_rules.to_json
            end

            super(tracing_sampling_rules)
            Datadog.send(:components).reconfigure_live_sampler
          end

          protected

          def configuration_object
            Datadog.configuration.tracing.sampling
          end
        end

        # List of all tracing dynamic configuration options supported.
        OPTIONS = [LogInjectionEnabled, TracingHeaderTags, TracingSamplingRate, TracingSamplingRules].map do |option_class|
          option = option_class.new
          [option.name, option.env_var, option]
        end
      end
    end
  end
end
