# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    # The configurator provides defaults and facilitates configuring the
    # SDK for use.
    class Configurator # rubocop:disable Metrics/ClassLength
      # @api private
      class NoopTextMapPropagator
        EMPTY_LIST = [].freeze
        private_constant(:EMPTY_LIST)

        def inject(carrier, context: Context.current, setter: Context::Propagation.text_map_setter); end

        def extract(carrier, context: Context.current, getter: Context::Propagation.text_map_getter)
          context
        end

        def fields
          EMPTY_LIST
        end
      end

      USE_MODE_UNSPECIFIED = 0
      USE_MODE_ONE = 1
      USE_MODE_ALL = 2

      private_constant :USE_MODE_UNSPECIFIED, :USE_MODE_ONE, :USE_MODE_ALL

      attr_writer :propagators, :error_handler, :id_generator

      def initialize
        @instrumentation_names = []
        @instrumentation_config_map = {}
        @propagators = nil
        @span_processors = []
        @use_mode = USE_MODE_UNSPECIFIED
        @resource = Resources::Resource.default
        @id_generator = OpenTelemetry::Trace
      end

      def logger
        @logger ||= OpenTelemetry.logger
      end

      # Accepts a logger and wraps it in the {ForwardingLogger} which allows
      # for controlling the severity level emitted by the OpenTelemetry.logger
      # independently of the supplied logger.
      #
      # @param [Logger] new_logger The logger for OpenTelemetry to use
      def logger=(new_logger)
        @logger = ForwardingLogger.new(new_logger, level: ENV['OTEL_LOG_LEVEL'] || Logger::INFO)
      end

      def error_handler
        @error_handler ||= OpenTelemetry.error_handler
      end

      # Accepts a resource object that is merged with the default telemetry sdk
      # resource. The use of this method is optional, and is provided as means
      # to include additional resource information.
      # If a resource key collision occurs the passed in resource takes priority.
      #
      # @param [Resource] new_resource The resource to be merged
      def resource=(new_resource)
        @resource = @resource.merge(new_resource)
      end

      # Accepts a string that is merged in as the service.name resource attribute.
      # The most recent assigned value will be used in the event of repeated
      # calls to this setter.
      # @param [String] service_name The value to be used as the service name
      def service_name=(service_name)
        self.resource = OpenTelemetry::SDK::Resources::Resource.create(
          OpenTelemetry::SemanticConventions::Resource::SERVICE_NAME => service_name
        )
      end

      # Accepts a string that is merged in as the service.version resource attribute.
      # The most recent assigned value will be used in the event of repeated
      # calls to this setter.
      # @param [String] service_version The value to be used as the service version
      def service_version=(service_version)
        self.resource = OpenTelemetry::SDK::Resources::Resource.create(
          OpenTelemetry::SemanticConventions::Resource::SERVICE_VERSION => service_version
        )
      end

      # Install an instrumentation with specified optional +config+.
      # Use can be called multiple times to install multiple instrumentation.
      # Only +use+ or +use_all+, but not both when installing
      # instrumentation. A call to +use_all+ after +use+ will result in an
      # exception.
      #
      # @param [String] instrumentation_name The name of the instrumentation
      # @param [optional Hash] config The config for this instrumentation
      def use(instrumentation_name, config = nil)
        check_use_mode!(USE_MODE_ONE)
        @instrumentation_names << instrumentation_name
        @instrumentation_config_map[instrumentation_name] = config if config
      end

      # Install all registered instrumentation. Configuration for specific
      # instrumentation can be provided with the optional +instrumentation_config_map+
      # parameter. Only +use+ or +use_all+, but not both when installing
      # instrumentation. A call to +use+ after +use_all+ will result in an
      # exception.
      #
      # @param [optional Hash<String,Hash>] instrumentation_config_map A map with string keys
      #   representing the instrumentation name and values specifying the instrumentation config
      def use_all(instrumentation_config_map = {})
        check_use_mode!(USE_MODE_ALL)
        @instrumentation_config_map = instrumentation_config_map
      end

      # Add a span processor to the export pipeline
      #
      # @param [#on_start, #on_finish, #shutdown, #force_flush] span_processor A span_processor
      #   that satisfies the duck type #on_start, #on_finish, #shutdown, #force_flush. See
      #   {SimpleSpanProcessor} for an example.
      def add_span_processor(span_processor)
        @span_processors << span_processor
      end

      # Add a log record processor to the export pipeline
      #
      # @param [#emit, #shutdown, #force_flush] log_record_processor A log_record_processor
      #   that satisfies the duck type #emit, #shutdown, #force_flush. See
      #   {SimpleLogRecordProcessor} for an example.
      def add_log_record_processor(log_record_processor); end

      # @api private
      # The configure method is where we define the setup process. This allows
      # us to make certain guarantees about which systems and globals are setup
      # at each stage. The setup process is:
      #   - setup logging
      #   - setup propagation
      #   - setup tracer_provider, meter_provider, and logger_provider
      #   - install instrumentation
      def configure
        OpenTelemetry.logger = logger
        OpenTelemetry.error_handler = error_handler
        configure_propagation
        configure_span_processors
        tracer_provider.id_generator = @id_generator
        OpenTelemetry.tracer_provider = tracer_provider
        metrics_configuration_hook
        logs_configuration_hook
        install_instrumentation
      end

      private

      def metrics_configuration_hook; end

      def logs_configuration_hook; end

      def tracer_provider
        @tracer_provider ||= Trace::TracerProvider.new(resource: @resource)
      end

      def check_use_mode!(mode)
        @use_mode = mode if @use_mode == USE_MODE_UNSPECIFIED
        raise 'Use either `use_all` or `use`, but not both' unless @use_mode == mode
      end

      def install_instrumentation
        case @use_mode
        when USE_MODE_ONE
          OpenTelemetry::Instrumentation.registry.install(@instrumentation_names, @instrumentation_config_map)
        when USE_MODE_ALL
          OpenTelemetry::Instrumentation.registry.install_all(@instrumentation_config_map)
        end
      end

      def configure_span_processors
        processors = @span_processors.empty? ? wrapped_exporters_from_env.compact : @span_processors
        processors.each { |p| tracer_provider.add_span_processor(p) }
      end

      def wrapped_exporters_from_env # rubocop:disable Metrics/CyclomaticComplexity
        exporters = ENV.fetch('OTEL_TRACES_EXPORTER', 'otlp')
        exporters.split(',').map do |exporter|
          case exporter.strip
          when 'none' then nil
          when 'otlp'
            otlp_protocol = ENV['OTEL_EXPORTER_OTLP_TRACES_PROTOCOL'] || ENV['OTEL_EXPORTER_OTLP_PROTOCOL'] || 'http/protobuf'

            if otlp_protocol != 'http/protobuf'
              OpenTelemetry.logger.warn "The #{otlp_protocol} transport protocol is not supported by the OTLP exporter, spans will not be exported."
              nil
            else
              fetch_exporter(exporter, 'OpenTelemetry::Exporter::OTLP::Exporter')
            end
          when 'jaeger' then fetch_exporter(exporter, 'OpenTelemetry::Exporter::Jaeger::CollectorExporter')
          when 'zipkin' then fetch_exporter(exporter, 'OpenTelemetry::Exporter::Zipkin::Exporter')
          when 'console' then Trace::Export::SimpleSpanProcessor.new(Trace::Export::ConsoleSpanExporter.new)
          else
            OpenTelemetry.logger.warn "The #{exporter} exporter is unknown and cannot be configured, spans will not be exported"
            nil
          end
        end
      end

      def configure_propagation # rubocop:disable Metrics/CyclomaticComplexity
        propagators = ENV.fetch('OTEL_PROPAGATORS', 'tracecontext,baggage').split(',').uniq.collect do |propagator|
          case propagator
          when 'tracecontext' then OpenTelemetry::Trace::Propagation::TraceContext.text_map_propagator
          when 'baggage' then OpenTelemetry::Baggage::Propagation.text_map_propagator
          when 'b3' then fetch_propagator(propagator, 'OpenTelemetry::Propagator::B3::Single')
          when 'b3multi' then fetch_propagator(propagator, 'OpenTelemetry::Propagator::B3::Multi', 'b3')
          when 'jaeger' then fetch_propagator(propagator, 'OpenTelemetry::Propagator::Jaeger')
          when 'xray' then fetch_propagator(propagator, 'OpenTelemetry::Propagator::XRay')
          when 'ottrace' then fetch_propagator(propagator, 'OpenTelemetry::Propagator::OTTrace')
          when 'none' then NoopTextMapPropagator.new
          else
            OpenTelemetry.logger.warn "The #{propagator} propagator is unknown and cannot be configured"
            NoopTextMapPropagator.new
          end
        end
        OpenTelemetry.propagation = Context::Propagation::CompositeTextMapPropagator.compose_propagators((@propagators || propagators).compact)
      end

      def fetch_propagator(name, class_name, gem_suffix = name)
        Kernel.const_get(class_name).text_map_propagator
      rescue NameError
        OpenTelemetry.logger.warn "The #{name} propagator cannot be configured - please add opentelemetry-propagator-#{gem_suffix} to your Gemfile"
        nil
      end

      def fetch_exporter(name, class_name)
        Trace::Export::BatchSpanProcessor.new(Kernel.const_get(class_name).new)
      rescue NameError
        OpenTelemetry.logger.warn "The #{name} exporter cannot be configured - please add opentelemetry-exporter-#{name} to your Gemfile, spans will not be exported"
        nil
      end
    end
  end
end
