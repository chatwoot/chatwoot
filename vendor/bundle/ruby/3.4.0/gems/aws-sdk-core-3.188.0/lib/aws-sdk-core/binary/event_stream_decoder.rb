# frozen_string_literal: true

require 'aws-eventstream'

module Aws
  module Binary
    # @api private
    class EventStreamDecoder

      # @param [String] protocol
      # @param [ShapeRef] rules ShapeRef of the eventstream member
      # @param [ShapeRef] output_ref ShapeRef of output shape
      # @param [Array] error_refs array of ShapeRefs for errors
      # @param [EventStream|nil] event_stream_handler A Service EventStream object
      # that registered with callbacks for processing events when they arrive
      def initialize(protocol, rules, output_ref, error_refs, io, event_stream_handler = nil)
        @decoder = Aws::EventStream::Decoder.new
        @event_parser = EventParser.new(parser_class(protocol), rules, error_refs, output_ref)
        @stream_class = extract_stream_class(rules.shape.struct_class)
        @emitter = event_stream_handler.event_emitter
        @events = []
      end

      # @return [Array] events Array of arrived event objects
      attr_reader :events

      def write(chunk)
        raw_event, eof = @decoder.decode_chunk(chunk)
        emit_event(raw_event) if raw_event
        while !eof
          # exhaust message_buffer data
          raw_event, eof = @decoder.decode_chunk
          emit_event(raw_event) if raw_event
        end
      end

      private

      def emit_event(raw_event)
        event = @event_parser.apply(raw_event)
        @events << event
        @emitter.signal(event.event_type, event) unless @emitter.nil?
      end

      def parser_class(protocol)
        case protocol
        when 'rest-xml' then Aws::Xml::Parser
        when 'rest-json' then Aws::Json::Parser
        when 'json' then Aws::Json::Parser
        else raise "unsupported protocol #{protocol} for event stream"
        end
      end

      def extract_stream_class(type_class)
        parts = type_class.to_s.split('::')
        parts.inject(Kernel) do |const, part_name|
          part_name == 'Types' ? const.const_get('EventStreams')
            : const.const_get(part_name)
        end
      end
    end

  end
end
