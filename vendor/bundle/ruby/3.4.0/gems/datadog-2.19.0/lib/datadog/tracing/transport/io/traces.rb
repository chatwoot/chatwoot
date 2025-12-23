# frozen_string_literal: true

require_relative '../../transport/traces'
require_relative '../../../core/transport/parcel'
require_relative 'response'
require_relative 'client'

module Datadog
  module Tracing
    module Transport
      module IO
        # IO transport behavior for traces
        module Traces
          # Response from HTTP transport for traces
          class Response < IO::Response
            include Transport::Traces::Response

            def initialize(result, trace_count = 1)
              super(result)
              @trace_count = trace_count
            end
          end

          # Extensions for HTTP client
          module Client
            def send_traces(traces)
              # Build a request
              req = Transport::Traces::Request.new(Parcel.new(traces))

              [send_request(req) do |out, request|
                # Encode trace data
                data = encode_data(encoder, request)

                # Write to IO
                result = if block_given?
                           yield(out, data)
                         else
                           write_data(out, data)
                         end

                # Generate response
                Traces::Response.new(result)
              end]
            end
          end

          # Encoder for IO-specific trace encoding
          # API compliant when used with {JSONEncoder}.
          module Encoder
            ENCODED_IDS = [
              :trace_id,
              :span_id,
              :parent_id
            ].freeze

            # Encodes a list of traces
            def encode_traces(encoder, traces)
              trace_hashes = traces.map do |trace|
                encode_trace(trace)
              end

              # Wrap traces & encode them
              encoder.encode(traces: trace_hashes)
            end

            private

            def encode_trace(trace)
              # Convert each trace to hash
              trace.spans.map(&:to_hash).tap do |spans|
                # Convert IDs to hexadecimal
                spans.each do |span|
                  ENCODED_IDS.each do |id|
                    span[id] = span[id].to_s(16) if span.key?(id)
                  end
                end
              end
            end
          end

          # Transfer object for list of traces
          class Parcel
            include Datadog::Core::Transport::Parcel
            include Encoder

            def count
              data.length
            end

            def encode_with(encoder)
              encode_traces(encoder, data)
            end
          end

          # Add traces behavior to transport components
          IO::Client.include(Traces::Client)
        end
      end
    end
  end
end
