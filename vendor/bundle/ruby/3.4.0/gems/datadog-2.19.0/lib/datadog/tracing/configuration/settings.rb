# frozen_string_literal: true

require_relative '../../tracing/configuration/ext'
require_relative '../../core/environment/variable_helpers'
require_relative 'http'

module Datadog
  module Tracing
    module Configuration
      # Configuration settings for tracing.
      # @public_api
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/BlockLength
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Layout/LineLength
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      module Settings
        def self.extended(base)
          base.class_eval do
            # Tracer specific configurations.
            # @public_api
            settings :tracing do
              # Legacy [App Analytics](https://docs.datadoghq.com/tracing/legacy_app_analytics/) configuration.
              #
              # @configure_with {Datadog::Tracing}
              # @deprecated Use [Trace Retention and Ingestion](https://docs.datadoghq.com/tracing/trace_retention_and_ingestion/)
              #   controls.
              # @!visibility private
              settings :analytics do
                # @default `DD_TRACE_ANALYTICS_ENABLED` environment variable, otherwise `nil`
                # @return [Boolean,nil]
                # @!visibility private
                option :enabled do |o|
                  o.type :bool, nilable: true
                  o.env Tracing::Configuration::Ext::Analytics::ENV_TRACE_ANALYTICS_ENABLED
                end
              end

              # An ordered, case-insensitive list of what data propagation styles the tracer will use to extract distributed tracing propagation
              # data from incoming requests and messages.
              #
              # The tracer will try to find distributed headers in the order they are present in the list provided to this option.
              # The first format to have valid data present will be used.
              # Baggage style is a special case, as it will always be extracted in addition if present.
              # @default `DD_TRACE_PROPAGATION_STYLE_EXTRACT` environment variable (comma-separated list),
              #   otherwise `['datadog','b3multi','b3']`.
              # @return [Array<String>]
              option :propagation_style_extract do |o|
                o.type :array
                o.env Tracing::Configuration::Ext::Distributed::ENV_PROPAGATION_STYLE_EXTRACT
                o.default(
                  [
                    Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_DATADOG,
                    Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_TRACE_CONTEXT,
                    Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_BAGGAGE,
                  ]
                )
                o.after_set do |styles|
                  # Make values case-insensitive
                  styles.map!(&:downcase)
                end
              end

              # The case-insensitive list of the data propagation styles the tracer will use to inject distributed tracing propagation
              # data into outgoing requests and messages.
              #
              # The tracer will inject data from all styles specified in this option.
              #
              # @default `DD_TRACE_PROPAGATION_STYLE_INJECT` environment variable (comma-separated list), otherwise `['datadog','tracecontext']`.
              # @return [Array<String>]
              option :propagation_style_inject do |o|
                o.type :array
                o.env Tracing::Configuration::Ext::Distributed::ENV_PROPAGATION_STYLE_INJECT
                o.default [
                  Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_DATADOG,
                  Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_TRACE_CONTEXT,
                  Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_BAGGAGE,
                ]
                o.after_set do |styles|
                  # Make values case-insensitive
                  styles.map!(&:downcase)
                end
              end

              # An ordered, case-insensitive list of what data propagation styles the tracer will use to extract distributed tracing propagation
              # data from incoming requests and inject into outgoing requests.
              #
              # This configuration is the equivalent of configuring both {propagation_style_extract}
              # {propagation_style_inject} to value set to {propagation_style}.
              #
              # @default `DD_TRACE_PROPAGATION_STYLE` environment variable (comma-separated list).
              # @return [Array<String>]
              option :propagation_style do |o|
                o.type :array
                o.env [Configuration::Ext::Distributed::ENV_PROPAGATION_STYLE, Configuration::Ext::Distributed::ENV_OTEL_PROPAGATION_STYLE]
                o.default []
                o.after_set do |styles|
                  next if styles.empty?

                  # Make values case-insensitive
                  styles.map!(&:downcase)

                  styles.select! do |s|
                    if Configuration::Ext::Distributed::PROPAGATION_STYLE_SUPPORTED.include?(s)
                      true
                    else
                      Datadog.logger.warn("Unsupported propagation style: #{s}")
                      false
                    end
                  end
                  set_option(:propagation_style_extract, styles)
                  set_option(:propagation_style_inject, styles)
                end
              end

              # Strictly stop at the first successfully serialized style.
              # This prevents the tracer from enriching the extracted context with information from
              # other valid propagations styles present in the request.
              # @default `DD_TRACE_PROPAGATION_EXTRACT_FIRST` environment variable, otherwise `false`.
              # @return [Boolean]
              option :propagation_extract_first do |o|
                o.env Tracing::Configuration::Ext::Distributed::EXTRACT_FIRST
                o.default false
                o.type :bool
              end

              # Enable trace collection and span generation.
              #
              # You can use this option to disable tracing without having to
              # remove the library as a whole.
              #
              # @default `DD_TRACE_ENABLED` environment variable, otherwise `true`
              # @return [Boolean]
              option :enabled do |o|
                o.env [Tracing::Configuration::Ext::ENV_ENABLED, Tracing::Configuration::Ext::ENV_OTEL_TRACES_EXPORTER]
                o.default true
                o.type :bool
                o.env_parser do |value|
                  value = value&.downcase
                  # Tracing is disabled when OTEL_TRACES_EXPORTER is none or
                  # DD_TRACE_ENABLED is 0 or false.
                  if ['none', 'false', '0'].include?(value)
                    false
                  # Tracing is enabled when DD_TRACE_ENABLED is true or 1
                  elsif ['true', '1'].include?(value)
                    true
                  else
                    Datadog.logger.warn("Unsupported value for exporting datadog traces: #{value}. Traces will be sent to Datadog.")
                    nil
                  end
                end
              end

              # Comma-separated, case-insensitive list of header names that are reported in incoming and outgoing HTTP requests.
              #
              # Each header in the list can either be:
              # * A header name, which is mapped to the respective tags `http.request.headers.<header name>` and `http.response.headers.<header name>`.
              # * A key value pair, "header name:tag name", which is mapped to the span tag `tag name`.
              #
              # You can mix the two types of header declaration in the same list.
              # Tag names will be normalized based on the [Datadog tag normalization rules](https://docs.datadoghq.com/getting_started/tagging/#defining-tags).
              #
              # @default `DD_TRACE_HEADER_TAGS` environment variable, otherwise an empty set of tags
              # @return [Array<String>]
              option :header_tags do |o|
                o.env Configuration::Ext::ENV_HEADER_TAGS
                o.type :array
                o.default []
                o.setter { |header_tags, _| Configuration::HTTP::HeaderTags.new(header_tags) }
              end

              # Enable 128 bit trace id generation.
              #
              # @default `DD_TRACE_128_BIT_TRACEID_GENERATION_ENABLED` environment variable, otherwise `true`
              # @return [Boolean]
              option :trace_id_128_bit_generation_enabled do |o|
                o.env Tracing::Configuration::Ext::ENV_TRACE_ID_128_BIT_GENERATION_ENABLED
                o.default true
                o.type :bool
              end

              # Enable 128 bit trace id injected for logging.
              #
              # @default `DD_TRACE_128_BIT_TRACEID_LOGGING_ENABLED` environment variable, otherwise `false`
              # @return [Boolean]
              #
              # It is not supported by our backend yet. Do not enable it.
              option :trace_id_128_bit_logging_enabled do |o|
                o.env Tracing::Configuration::Ext::Correlation::ENV_TRACE_ID_128_BIT_LOGGING_ENABLED
                o.default true
                o.type :bool
              end

              # A custom tracer instance.
              #
              # It must respect the contract of {Datadog::Tracing::Tracer}.
              # It's recommended to delegate methods to {Datadog::Tracing::Tracer} to ease the implementation
              # of a custom tracer.
              #
              # This option will not return the live tracer instance: it only holds a custom tracing instance, if any.
              #
              # For internal use only.
              #
              # @default `nil`
              # @return [Object,nil]
              option :instance

              # Automatic correlation between tracing and logging.
              # @see https://docs.datadoghq.com/tracing/setup_overview/setup/ruby/#trace-correlation
              # @return [Boolean]
              option :log_injection do |o|
                o.env Tracing::Configuration::Ext::Correlation::ENV_LOGS_INJECTION_ENABLED
                o.default true
                o.type :bool
              end

              # Configures an alternative trace transport behavior, where
              # traces can be sent to the agent and backend before all spans
              # have finished.
              #
              # This is useful for long-running jobs or very large traces.
              #
              # The trace flame graph will display the partial trace as it is received and constantly
              # update with new spans as they are flushed.
              # @public_api
              settings :partial_flush do
                # Enable partial trace flushing.
                #
                # @default `false`
                # @return [Boolean]
                option :enabled, default: false, type: :bool

                # Minimum number of finished spans required in a single unfinished trace before
                # the tracer will consider that trace for partial flushing.
                #
                # This option helps preserve a minimum amount of batching in the
                # flushing process, reducing network overhead.
                #
                # This threshold only applies to unfinished traces. Traces that have finished
                # are always flushed immediately.
                #
                # @default 500
                # @return [Integer]
                option :min_spans_threshold, default: 500, type: :int
              end

              option :report_hostname do |o|
                o.env Tracing::Configuration::Ext::NET::ENV_REPORT_HOSTNAME
                o.default false
                o.type :bool
              end

              # Forces the tracer to always send span events with the native span events format
              # regardless of the agent support. This is useful in agent-less setups.
              #
              # When set to `nil`, the default, the agent will be queried for
              # native span events support.
              #
              # @default `DD_TRACE_NATIVE_SPAN_EVENTS` environment variable, otherwise `false`
              # @return [Boolean,nil]
              option :native_span_events do |o|
                o.env Tracing::Configuration::Ext::ENV_NATIVE_SPAN_EVENTS
                o.default nil
                o.type :bool, nilable: true
              end

              # A custom sampler instance.
              # The object must respect the {Datadog::Tracing::Sampling::Sampler} interface.
              # @default `nil`
              # @return [Object,nil]
              option :sampler

              # Client-side sampling configuration.
              # @see https://docs.datadoghq.com/tracing/trace_ingestion/mechanisms/
              # @public_api
              settings :sampling do
                # Default sampling rate for the tracer.
                #
                # If `nil`, the trace uses an automatic sampling strategy that tries to ensure
                # the collection of traces that are considered important (e.g. traces with an error, traces
                # for resources not seen recently).
                #
                # @default `DD_TRACE_SAMPLE_RATE` environment variable, otherwise `nil`.
                # @return [Float, nil]
                option :default_rate do |o|
                  o.type :float, nilable: true
                  o.env [Tracing::Configuration::Ext::Sampling::ENV_SAMPLE_RATE, Tracing::Configuration::Ext::Sampling::ENV_OTEL_TRACES_SAMPLER]
                  o.env_parser do |value|
                    # Parse the value as a float
                    next if value.nil?

                    value = value&.downcase
                    if ['always_on', 'always_off', 'traceidratio'].include?(value)
                      Datadog.logger.warn("The value '#{value}' is not yet supported. 'parentbased_#{value}' will be used instead.")
                      value = "parentbased_#{value}"
                    end
                    # OTEL_TRACES_SAMPLER can be set to always_on, always_off, traceidratio, and/or parentbased value.
                    # These values are mapped to a sample rate.
                    # DD_TRACE_SAMPLE_RATE sets the sample rate to float.
                    case value
                    when 'parentbased_always_on'
                      1.0
                    when 'parentbased_always_off'
                      0.0
                    when 'parentbased_traceidratio'
                      ENV.fetch(Tracing::Configuration::Ext::Sampling::OTEL_TRACES_SAMPLER_ARG, 1.0).to_f
                    else
                      value.to_f
                    end
                  end
                end

                # Rate limit for number of spans per second.
                #
                # Spans created above the limit will contribute to service metrics, but won't
                # have their payload stored.
                #
                # @default `DD_TRACE_RATE_LIMIT` environment variable, otherwise 100.
                # @return [Numeric,nil]
                option :rate_limit do |o|
                  o.type :int, nilable: true
                  o.env Tracing::Configuration::Ext::Sampling::ENV_RATE_LIMIT
                  o.default 100
                end

                # Trace sampling rules.
                # These rules control whether a trace is kept or dropped by the tracer.
                #
                # The `rules` format is a String with a JSON array of objects:
                # Each object must have a `sample_rate`, and the `name` and `service` fields
                # are optional. The `sample_rate` value must be between 0.0 and 1.0 (inclusive).
                # `name` and `service` are Strings that allow the `sample_rate` to be applied only
                # to traces matching the `name` and `service`.
                #
                # @default `DD_TRACE_SAMPLING_RULES` environment variable. Otherwise `nil`.
                # @return [String,nil]
                # @public_api
                option :rules do |o|
                  o.type :string, nilable: true
                  o.default { ENV.fetch(Configuration::Ext::Sampling::ENV_RULES, nil) }
                end

                # Single span sampling rules.
                # These rules allow a span to be kept when its encompassing trace is dropped.
                #
                # The syntax for single span sampling rules can be found here:
                # TODO: <Single Span Sampling documentation URL here>
                #
                # @default `DD_SPAN_SAMPLING_RULES` environment variable.
                #   Otherwise, `ENV_SPAN_SAMPLING_RULES_FILE` environment variable.
                #   Otherwise `nil`.
                # @return [String,nil]
                # @public_api
                option :span_rules do |o|
                  o.type :string, nilable: true
                  o.default do
                    rules = ENV[Tracing::Configuration::Ext::Sampling::Span::ENV_SPAN_SAMPLING_RULES]
                    rules_file = ENV[Tracing::Configuration::Ext::Sampling::Span::ENV_SPAN_SAMPLING_RULES_FILE]

                    if rules
                      if rules_file
                        Datadog.logger.warn(
                          'Both DD_SPAN_SAMPLING_RULES and DD_SPAN_SAMPLING_RULES_FILE were provided: only ' \
                            'DD_SPAN_SAMPLING_RULES will be used. Please do not provide DD_SPAN_SAMPLING_RULES_FILE when ' \
                            'also providing DD_SPAN_SAMPLING_RULES as their configuration conflicts. ' \
                            "DD_SPAN_SAMPLING_RULES_FILE=#{rules_file} DD_SPAN_SAMPLING_RULES=#{rules}"
                        )
                      end
                      rules
                    elsif rules_file
                      begin
                        File.read(rules_file)
                      rescue => e
                        # `File#read` errors have clear and actionable messages, no need to add extra exception info.
                        Datadog.logger.warn(
                          "Cannot read span sampling rules file `#{rules_file}`: #{e.message}." \
                          'No span sampling rules will be applied.'
                        )
                        nil
                      end
                    end
                  end
                end
              end

              # This is only for internal Datadog use via https://github.com/DataDog/datadog-ci-rb . It should not be
              # used directly.
              #
              # DEV-3.0: Make this a non-public API in the next release.
              # @public_api
              settings :test_mode do
                option :enabled do |o|
                  o.type :bool
                  o.default false
                  o.env Tracing::Configuration::Ext::Test::ENV_MODE_ENABLED
                end

                option :async do |o|
                  o.type :bool
                  o.default false
                end

                option :trace_flush

                option :writer_options do |o|
                  o.type :hash
                  o.default({})
                end
              end

              # A custom writer instance.
              # The object must respect the {Datadog::Tracing::Writer} interface.
              #
              # This option is recommended for internal use only.
              #
              # @default `nil`
              # @return [Object,nil]
              option :writer

              # A custom {Hash} with keyword options to be passed to {Datadog::Tracing::Writer#initialize}.
              #
              # This option is recommended for internal use only.
              #
              # @default `{}`
              # @return [Hash]
              option :writer_options do |o|
                o.type :hash
                o.default({})
              end

              # Client IP configuration
              # @public_api
              settings :client_ip do
                # Whether client IP collection is enabled. When enabled client IPs from HTTP requests will
                #   be reported in traces.
                #
                # @see https://docs.datadoghq.com/tracing/configure_data_security#configuring-a-client-ip-header
                #
                # @default `DD_TRACE_CLIENT_IP_ENABLED` environment variable, otherwise `false`.
                # @return [Boolean]
                option :enabled do |o|
                  o.type :bool
                  o.env Tracing::Configuration::Ext::ClientIp::ENV_ENABLED
                  o.default false
                end

                # An optional name of a custom header to resolve the client IP from.
                #
                # @default `DD_TRACE_CLIENT_IP_HEADER` environment variable, otherwise `nil`.
                # @return [String,nil]
                option :header_name do |o|
                  o.type :string, nilable: true
                  o.env Tracing::Configuration::Ext::ClientIp::ENV_HEADER_NAME
                end
              end

              # Maximum size for the `x-datadog-tags` distributed trace tags header.
              #
              # If the serialized size of distributed trace tags is larger than this value, it will
              # not be parsed if incoming, nor exported if outgoing. An error message will be logged
              # in this case.
              #
              # @default `DD_TRACE_X_DATADOG_TAGS_MAX_LENGTH` environment variable, otherwise `512`
              # @return [Integer]
              option :x_datadog_tags_max_length do |o|
                o.type :int
                o.env Tracing::Configuration::Ext::Distributed::ENV_X_DATADOG_TAGS_MAX_LENGTH
                o.default 512
              end
            end
          end
        end
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/BlockLength
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Layout/LineLength
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity
    end
  end
end
