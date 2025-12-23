# frozen_string_literal: true

require_relative '../../core/chunker'
require_relative '../../core/transport/parcel'
require_relative '../../core/transport/request'
require_relative 'serializable_trace'
require_relative 'trace_formatter'

module Datadog
  module Tracing
    module Transport
      module Traces
        # Data transfer object for encoded traces
        class EncodedParcel
          include Datadog::Core::Transport::Parcel

          attr_reader :trace_count

          def initialize(data, trace_count)
            super(data)
            @trace_count = trace_count
          end

          def count
            data.length
          end
        end

        # Traces request
        class Request < Datadog::Core::Transport::Request
        end

        # Traces response
        module Response
          attr_reader :service_rates, :trace_count
        end

        # Traces chunker
        class Chunker
          # Trace agent limit payload size of 10 MiB (since agent v5.11.0):
          # https://github.com/DataDog/datadog-agent/blob/6.14.1/pkg/trace/api/api.go#L46
          #
          # We set the value to a conservative 5 MiB, in case network speed is slow.
          DEFAULT_MAX_PAYLOAD_SIZE = 5 * 1024 * 1024

          attr_reader :encoder, :max_size, :logger

          #
          # Single traces larger than +max_size+ will be discarded.
          #
          # @param encoder [Datadog::Core::Encoding::Encoder]
          # @param logger [Datadog::Core::Logger]
          # @param max_size [String] maximum acceptable payload size
          def initialize(encoder, logger:, native_events_supported:, max_size: DEFAULT_MAX_PAYLOAD_SIZE)
            @encoder = encoder
            @logger = logger
            @native_events_supported = native_events_supported
            @max_size = max_size
          end

          # Encodes a list of traces in chunks.
          # Before serializing, all traces are normalized. Trace nesting is not changed.
          #
          # @param traces [Enumerable<Trace>] list of traces
          # @return [Enumerable[Array[Bytes,Integer]]] list of encoded chunks: each containing a byte array and
          #   number of traces
          def encode_in_chunks(traces)
            encoded_traces = if traces.respond_to?(:filter_map)
                               # DEV Supported since Ruby 2.7, saves an intermediate object creation
                               traces.filter_map { |t| encode_one(t) }
                             else
                               traces.map { |t| encode_one(t) }.reject(&:nil?)
                             end

            Datadog::Core::Chunker.chunk_by_size(encoded_traces, max_size).map do |chunk|
              [encoder.join(chunk), chunk.size]
            end
          end

          private

          def encode_one(trace)
            encoded = Encoder.encode_trace(
              encoder,
              trace,
              logger: logger,
              native_events_supported: @native_events_supported
            )

            if encoded.size > max_size
              # This single trace is too large, we can't flush it
              logger.debug { "Dropping trace. Payload too large: '#{trace.inspect}'" }
              Datadog.health_metrics.transport_trace_too_large(1)

              return nil
            end

            encoded
          end
        end

        # Encodes traces using {Datadog::Core::Encoding::Encoder} instances.
        module Encoder
          module_function

          def encode_trace(encoder, trace, logger:, native_events_supported:)
            # Format the trace for transport
            TraceFormatter.format!(trace)

            # Make the trace serializable
            serializable_trace = SerializableTrace.new(trace, native_events_supported: native_events_supported)

            # Encode the trace
            encoder.encode(serializable_trace).tap do |encoded|
              # Print the actual serialized trace, since the encoder can change make non-trivial changes
              logger.debug { "Flushing trace: #{encoder.decode(encoded)}" }
            end
          end
        end

        # Sends traces based on transport API configuration.
        #
        # This class initializes the HTTP client, breaks down large
        # batches of traces into smaller chunks and handles
        # API version downgrade handshake.
        class Transport
          attr_reader :client, :apis, :default_api, :current_api_id, :logger

          def initialize(apis, default_api, logger: Datadog.logger)
            @apis = apis
            @default_api = default_api
            @logger = logger

            change_api!(default_api)
          end

          def send_traces(traces)
            encoder = current_api.encoder
            chunker = Datadog::Tracing::Transport::Traces::Chunker.new(
              encoder,
              logger: logger,
              native_events_supported: native_events_supported?
            )

            responses = chunker.encode_in_chunks(traces.lazy).map do |encoded_traces, trace_count|
              request = Request.new(EncodedParcel.new(encoded_traces, trace_count))

              client.send_traces_payload(request).tap do |response|
                if downgrade?(response)
                  downgrade!
                  return send_traces(traces)
                end
              end
            end

            # Force resolution of lazy enumerator.
            #
            # The "correct" method to call here would be `#force`,
            # as this method was created to force the eager loading
            # of a lazy enumerator.
            #
            # Unfortunately, JRuby < 9.2.9.0 erroneously eagerly loads
            # the lazy Enumerator during intermediate steps.
            # This forces us to use `#to_a`, as this method works for both
            # lazy and regular Enumerators.
            # Using `#to_a` can mask the fact that we expect a lazy
            # Enumerator.
            responses = responses.to_a

            Datadog.health_metrics.transport_chunked(responses.size)

            responses
          end

          def stats
            @client.stats
          end

          def current_api
            apis[@current_api_id]
          end

          private

          def downgrade?(response)
            return false unless apis.fallbacks.key?(@current_api_id)

            response.not_found? || response.unsupported?
          end

          def downgrade!
            downgrade_api_id = apis.fallbacks[@current_api_id]
            raise NoDowngradeAvailableError, @current_api_id if downgrade_api_id.nil?

            change_api!(downgrade_api_id)
          end

          def change_api!(api_id)
            raise UnknownApiVersionError, api_id unless apis.key?(api_id)

            @current_api_id = api_id
            @client = HTTP::Client.new(current_api, logger: logger)
          end

          # Queries the agent for native span events serialization support.
          # This changes how the serialization of span events performed.
          def native_events_supported?
            return @native_events_supported if defined?(@native_events_supported)

            # Check for an explicit override
            option = Datadog.configuration.tracing.native_span_events
            unless option.nil?
              @native_events_supported = option
              return option
            end

            # Otherwise, check for agent support, to ensure a configuration-less setup.
            if (res = Datadog.send(:components).agent_info.fetch)
              @native_events_supported = res.span_events == true
            else
              false
            end
          end

          # Raised when configured with an unknown API version
          class UnknownApiVersionError < StandardError
            attr_reader :version

            def initialize(version)
              super

              @version = version
            end

            def message
              "No matching transport API for version #{version}!"
            end
          end

          # Raised when configured with an unknown API version
          class NoDowngradeAvailableError < StandardError
            attr_reader :version

            def initialize(version)
              super

              @version = version
            end

            def message
              "No downgrade from transport API version #{version} is available!"
            end
          end
        end
      end
    end
  end
end
