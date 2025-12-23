# frozen_string_literal: true

require 'aws-eventstream'

module Aws
  module Binary
    # @api private
    class EventStreamEncoder

      # @param [String] protocol
      # @param [ShapeRef] rules ShapeRef of the eventstream member
      # @param [ShapeRef] input_ref ShapeRef of the input shape
      # @param [Aws::Sigv4::Signer] signer
      def initialize(protocol, rules, input_ref, signer)
        @encoder = Aws::EventStream::Encoder.new
        @event_builder = EventBuilder.new(serializer_class(protocol), rules)
        @input_ref = input_ref
        @rules = rules
        @signer = signer
        @prior_signature = nil
      end

      attr_reader :rules

      attr_accessor :prior_signature

      def encode(event_type, params)
        if event_type == :end_stream
          payload = ''
        else
          payload = @encoder.encode(@event_builder.apply(event_type, params))
        end
        headers, signature = @signer.sign_event(@prior_signature, payload, @encoder)
        @prior_signature = signature
        message = Aws::EventStream::Message.new(
          headers: headers,
          payload: StringIO.new(payload)
        )
        @encoder.encode(message)
      end

      private

      def serializer_class(protocol)
        case protocol
        when 'rest-xml' then Xml::Builder
        when 'rest-json' then Json::Builder
        when 'json' then Json::Builder
        else raise "unsupported protocol #{protocol} for event stream"
        end
      end

    end
  end
end
