# frozen_string_literal: true

require_relative 'base'

module Datadog
  module Core
    module Telemetry
      module Event
        # Telemetry class for the 'app-started' event
        class AppStarted < Base
          def initialize(agent_settings:)
            @agent_settings = agent_settings
          end

          def type
            'app-started'
          end

          def payload
            {
              products: products,
              configuration: configuration,
              install_signature: install_signature,
              # DEV: Not implemented yet
              # error: error, # Start-up errors
            }
          end

          private

          def products
            # @type var products: Hash[Symbol, Hash[Symbol, Hash[Symbol, String | Integer] | bool | nil]]
            products = {
              appsec: {
                enabled: Datadog::AppSec.enabled?,
              },
              profiler: {
                enabled: Datadog::Profiling.enabled?,
              },
              dynamic_instrumentation: {
                enabled: defined?(Datadog::DI) && Datadog::DI.respond_to?(:enabled?) && Datadog::DI.enabled?,
              }
            }

            if (unsupported_reason = Datadog::Profiling.unsupported_reason)
              products[:profiler][:error] = {
                code: 1, # Error code. 0 if no error.
                message: unsupported_reason,
              }
            end

            products
          end

          TARGET_OPTIONS = %w[
            dynamic_instrumentation.enabled
            logger.level
            profiling.advanced.code_provenance_enabled
            profiling.advanced.endpoint.collection.enabled
            profiling.enabled
            runtime_metrics.enabled
            tracing.analytics.enabled
            tracing.propagation_style_extract
            tracing.propagation_style_inject
            tracing.enabled
            tracing.log_injection
            tracing.partial_flush.enabled
            tracing.partial_flush.min_spans_threshold
            tracing.report_hostname
            tracing.sampling.rate_limit
            apm.tracing.enabled
          ].freeze

          # standard:disable Metrics/AbcSize
          # standard:disable Metrics/MethodLength
          def configuration
            config = Datadog.configuration
            seq_id = Event.configuration_sequence.next

            # tracing.writer_options.buffer_size and tracing.writer_options.flush_interval have the same origin.
            writer_option_origin = get_telemetry_origin(config, 'tracing.writer_options')

            list = [
              # Only set using env var as of June 2025
              conf_value('DD_GIT_REPOSITORY_URL', Core::Environment::Git.git_repository_url, seq_id, 'env_var'),
              conf_value('DD_GIT_COMMIT_SHA', Core::Environment::Git.git_commit_sha, seq_id, 'env_var'),

              # Set by the customer application (eg. `require 'datadog/auto_instrument'`)
              conf_value(
                'tracing.auto_instrument.enabled',
                !defined?(Datadog::AutoInstrument::LOADED).nil?,
                seq_id,
                'code'
              ),
              conf_value(
                'tracing.opentelemetry.enabled',
                !defined?(Datadog::OpenTelemetry::LOADED).nil?,
                seq_id,
                'code'
              ),

              # Mix of env var, programmatic and default config, so we use unknown
              conf_value('DD_AGENT_TRANSPORT', agent_transport, seq_id, 'unknown'),

              # writer_options is defined as an option that has a Hash value.
              conf_value(
                'tracing.writer_options.buffer_size',
                to_value(config.tracing.writer_options[:buffer_size]),
                seq_id,
                writer_option_origin
              ),
              conf_value(
                'tracing.writer_options.flush_interval',
                to_value(config.tracing.writer_options[:flush_interval]),
                seq_id,
                writer_option_origin
              ),

              conf_value('DD_AGENT_HOST', config.agent.host, seq_id, get_telemetry_origin(config, 'agent.host')),
              conf_value(
                'DD_TRACE_SAMPLE_RATE',
                to_value(config.tracing.sampling.default_rate),
                seq_id,
                get_telemetry_origin(config, 'tracing.sampling.default_rate')
              ),
              conf_value(
                'DD_TRACE_REMOVE_INTEGRATION_SERVICE_NAMES_ENABLED',
                config.tracing.contrib.global_default_service_name.enabled,
                seq_id,
                get_telemetry_origin(config, 'tracing.contrib.global_default_service_name.enabled')
              ),
              conf_value(
                'DD_TRACE_PEER_SERVICE_DEFAULTS_ENABLED',
                config.tracing.contrib.peer_service_defaults,
                seq_id,
                get_telemetry_origin(config, 'tracing.contrib.peer_service_defaults')
              ),
              conf_value(
                'DD_TRACE_DEBUG',
                config.diagnostics.debug,
                seq_id,
                get_telemetry_origin(config, 'diagnostics.debug')
              )
            ]

            peer_service_mapping_str = ''
            unless config.tracing.contrib.peer_service_mapping.empty?
              peer_service_mapping = config.tracing.contrib.peer_service_mapping
              peer_service_mapping_str = peer_service_mapping.map { |key, value| "#{key}:#{value}" }.join(',')
            end
            list << conf_value(
              'DD_TRACE_PEER_SERVICE_MAPPING',
              peer_service_mapping_str,
              seq_id,
              get_telemetry_origin(config, 'tracing.contrib.peer_service_mapping')
            )

            # Whitelist of configuration options to send in additional payload object
            TARGET_OPTIONS.each do |option_path|
              split_option = option_path.split('.')
              list << conf_value(
                option_path,
                to_value(config.dig(*split_option)),
                seq_id,
                get_telemetry_origin(config, option_path)
              )
            end

            instrumentation_source = if Datadog.const_defined?(:SingleStepInstrument, false) &&
                Datadog::SingleStepInstrument.const_defined?(:LOADED, false) &&
                Datadog::SingleStepInstrument::LOADED
              'ssi'
            else
              'manual'
            end
            # Track ssi configurations
            list.push(
              conf_value('instrumentation_source', instrumentation_source, seq_id, 'code'),
              conf_value('DD_INJECT_FORCE', Core::Environment::VariableHelpers.env_to_bool('DD_INJECT_FORCE', false), seq_id, 'env_var'),
              conf_value('DD_INJECTION_ENABLED', ENV['DD_INJECTION_ENABLED'] || '', seq_id, 'env_var'),
            )

            # Add some more custom additional payload values here
            if config.logger.instance
              list << conf_value(
                'logger.instance',
                config.logger.instance.class.to_s,
                seq_id,
                get_telemetry_origin(config, 'logger.instance')
              )
            end
            if config.respond_to?('appsec')
              list << conf_value(
                'appsec.enabled',
                config.dig('appsec', 'enabled'),
                seq_id,
                get_telemetry_origin(config, 'appsec.enabled')
              )
              list << conf_value(
                'appsec.sca_enabled',
                config.dig('appsec', 'sca_enabled'),
                seq_id,
                get_telemetry_origin(config, 'appsec.sca_enabled')
              )
            end
            if config.respond_to?('ci')
              list << conf_value(
                'ci.enabled',
                config.dig('ci', 'enabled'),
                seq_id,
                get_telemetry_origin(config, 'ci.enabled')
              )
            end

            list.reject! { |entry| entry[:value].nil? }
            list
          end
          # standard:enable Metrics/AbcSize
          # standard:enable Metrics/MethodLength

          def agent_transport
            adapter = @agent_settings.adapter
            if adapter == Datadog::Core::Transport::Ext::UnixSocket::ADAPTER
              'UDS'
            else
              'TCP'
            end
          end

          # `origin`: Source of the configuration. One of :
          # - `fleet_stable_config`: configuration is set via the fleet automation Datadog UI
          # - `local_stable_config`: configuration set via a user-managed file
          # - `env_var`: configurations that are set through environment variables
          # - `jvm_prop`: JVM system properties passed on the command line
          # - `code`: configurations that are set through the customer application
          # - `dd_config`: set by the dd.yaml file or json
          # - `remote_config`: values that are set using remote config
          # - `app.config`: only applies to .NET
          # - `default`: set when the user has not set any configuration for the key (defaults to a value)
          # - `unknown`: set for cases where it is difficult/not possible to determine the source of a config.
          def conf_value(name, value, seq_id, origin)
            result = {name: name, value: value, origin: origin, seq_id: seq_id}
            if origin == 'fleet_stable_config'
              fleet_id = Core::Configuration::StableConfig.configuration.dig(:fleet, :id)
              result[:config_id] = fleet_id if fleet_id
            elsif origin == 'local_stable_config'
              local_id = Core::Configuration::StableConfig.configuration.dig(:local, :id)
              result[:config_id] = local_id if local_id
            end
            result
          end

          def to_value(value)
            # TODO: Add float if telemetry starts accepting it
            case value
            when Integer, String, true, false, nil
              value
            else
              value.to_s
            end
          end

          def install_signature
            config = Datadog.configuration
            {
              install_id: config.dig('telemetry', 'install_id'),
              install_type: config.dig('telemetry', 'install_type'),
              install_time: config.dig('telemetry', 'install_time'),
            }
          end

          def get_telemetry_origin(config, config_path)
            split_option = config_path.split('.')
            option_name = split_option.pop
            return 'unknown' if option_name.nil?

            # @type var parent_setting: Core::Configuration::Options
            # @type var option: Core::Configuration::Option
            parent_setting = config.dig(*split_option)
            option = parent_setting.send(:resolve_option, option_name.to_sym)
            option.precedence_set&.origin || 'unknown'
          end
        end
      end
    end
  end
end
