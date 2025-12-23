# frozen_string_literal: true

require 'json'
require 'msgpack'
require 'datadog/tracing/utils'

module Datadog
  module Tracing
    module Transport
      # Adds serialization functions to a {Datadog::TraceSegment}
      class SerializableTrace
        attr_reader \
          :trace

        # @param trace [Datadog::Trace] the trace to serialize
        # @param native_events_supported [Boolean] whether the agent supports span events as a top-level field
        def initialize(trace, native_events_supported:)
          @trace = trace
          @native_events_supported = native_events_supported
        end

        # MessagePack serializer interface. Making this object
        # respond to `#to_msgpack` allows it to be automatically
        # serialized by MessagePack.
        #
        # This is more efficient than doing +MessagePack.pack(span.to_hash)+
        # as we don't have to create an intermediate Hash.
        #
        # @param packer [MessagePack::Packer] serialization buffer, can be +nil+ with JRuby
        def to_msgpack(packer = nil)
          # As of 1.3.3, JRuby implementation doesn't pass an existing packer
          trace.spans.map do |s|
            SerializableSpan.new(s, native_events_supported: @native_events_supported)
          end.to_msgpack(packer)
        end

        # JSON serializer interface.
        # Used by older version of the transport.
        def to_json(*args)
          trace.spans.map do |s|
            SerializableSpan.new(s, native_events_supported: @native_events_supported).to_hash
          end.to_json(*args)
        end
      end

      # Adds serialization functions to a {Datadog::Span}
      class SerializableSpan
        attr_reader \
          :span

        # @param span [Datadog::Span] the span to serialize
        # @param native_events_supported [Boolean] whether the agent supports span events as a top-level field
        def initialize(span, native_events_supported:)
          @span = span
          @trace_id = Tracing::Utils::TraceId.to_low_order(span.trace_id)
          @native_events_supported = native_events_supported
        end

        # MessagePack serializer interface. Making this object
        # respond to `#to_msgpack` allows it to be automatically
        # serialized by MessagePack.
        #
        # This is more efficient than doing +MessagePack.pack(span.to_hash)+
        # as we don't have to create an intermediate Hash.
        #
        # @param packer [MessagePack::Packer] serialization buffer, can be +nil+ with JRuby
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/MethodLength
        def to_msgpack(packer = nil)
          packer ||= MessagePack::Packer.new

          number_of_elements_to_write = 12

          number_of_elements_to_write += 1 if span.events.any? && @native_events_supported

          if span.stopped?
            packer.write_map_header(number_of_elements_to_write + 2) # Set header with how many elements in the map

            packer.write('start')
            packer.write(time_nano(span.start_time))

            packer.write('duration')
            packer.write(duration_nano(span.duration))
          else
            packer.write_map_header(number_of_elements_to_write) # Set header with how many elements in the map
          end

          if span.events.any?
            if @native_events_supported
              # Use top-level field for native events
              packer.write('span_events')
              packer.write(span.events.map(&:to_native_format))
            else
              # Serialize span events as meta tags
              span.set_tag('events', span.events.map(&:to_hash).to_json)
            end
          end

          # DEV: We use strings as keys here, instead of symbols, as
          # DEV: MessagePack will ultimately convert them to strings.
          # DEV: By providing strings directly, we skip this indirection operation.
          packer.write('span_id')
          packer.write(span.id)
          packer.write('parent_id')
          packer.write(span.parent_id)
          packer.write('trace_id')
          packer.write(@trace_id)
          packer.write('name')
          packer.write(span.name)
          packer.write('service')
          packer.write(span.service)
          packer.write('resource')
          packer.write(span.resource)
          packer.write('type')
          packer.write(span.type)
          packer.write('meta')
          packer.write(span.meta)
          packer.write('metrics')
          packer.write(span.metrics)
          packer.write('meta_struct')
          packer.write(span.metastruct)
          packer.write('span_links')
          packer.write(span.links.map(&:to_hash))
          packer.write('error')
          packer.write(span.status)
          packer
        end
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/MethodLength

        # JSON serializer interface.
        # Used by older version of the transport.
        def to_json(*args)
          to_hash.to_json(*args)
        end

        # Used for serialization
        # @return [Integer] in nanoseconds since Epoch
        def time_nano(time)
          time.to_i * 1000000000 + time.nsec
        end

        def to_hash
          span.to_hash.merge(trace_id: @trace_id)
        end

        # Used for serialization
        # @return [Integer] in nanoseconds since Epoch
        def duration_nano(duration)
          (duration * 1e9).to_i
        end
      end
    end
  end
end
