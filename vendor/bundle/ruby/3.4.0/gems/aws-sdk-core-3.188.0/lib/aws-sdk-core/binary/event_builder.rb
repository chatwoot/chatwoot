# frozen_string_literal: true

module Aws
  module Binary
    # @api private
    class EventBuilder

      include Seahorse::Model::Shapes

      # @param [Class] serializer_class
      # @param [Seahorse::Model::ShapeRef] rules (of eventstream member)
      def initialize(serializer_class, rules)
        @serializer_class = serializer_class
        @rules = rules
      end

      def apply(event_type, params)
        event_ref = @rules.shape.member(event_type)
        _event_stream_message(event_ref, params)
      end

      private

      def _event_stream_message(event_ref, params)
        es_headers = {}
        payload = ""

        es_headers[":message-type"] = Aws::EventStream::HeaderValue.new(
          type: "string", value: "event")
        es_headers[":event-type"] = Aws::EventStream::HeaderValue.new(
          type: "string", value: event_ref.location_name)

        explicit_payload = false
        implicit_payload_members = {}
        event_ref.shape.members.each do |member_name, member_ref|
          unless member_ref.eventheader
            if member_ref.eventpayload
              explicit_payload = true
            else
              implicit_payload_members[member_name] = member_ref
            end
          end
        end

        # implict payload
        if !explicit_payload && !implicit_payload_members.empty?
          if implicit_payload_members.size > 1
            payload_shape = Shapes::StructureShape.new
            implicit_payload_members.each do |m_name, m_ref|
              payload_shape.add_member(m_name, m_ref)
            end
            payload_ref = Shapes::ShapeRef.new(shape: payload_shape)

            payload = build_payload_members(payload_ref, params)
          else
            m_name, m_ref = implicit_payload_members.first
            streaming, content_type = _content_type(m_ref.shape)

            es_headers[":content-type"] = Aws::EventStream::HeaderValue.new(
              type: "string", value: content_type)
            payload = _build_payload(streaming, m_ref, params[m_name])
          end
        end


        event_ref.shape.members.each do |member_name, member_ref|
          if member_ref.eventheader && params[member_name]
            header_value = params[member_name]
            es_headers[member_ref.shape.name] = Aws::EventStream::HeaderValue.new(
              type: _header_value_type(member_ref.shape, header_value),
              value: header_value
            )
          elsif member_ref.eventpayload && params[member_name]
            # explicit payload
            streaming, content_type = _content_type(member_ref.shape)

            es_headers[":content-type"] = Aws::EventStream::HeaderValue.new(
              type: "string", value: content_type)
            payload = _build_payload(streaming, member_ref, params[member_name])
          end
        end

        Aws::EventStream::Message.new(
          headers: es_headers,
          payload: StringIO.new(payload)
        )
      end

      def _content_type(shape)
        case shape
        when BlobShape then [true, "application/octet-stream"]
        when StringShape then [true, "text/plain"]
        when StructureShape then
          if @serializer_class.name.include?('Xml')
            [false, "text/xml"]
          elsif @serializer_class.name.include?('Json')
            [false, "application/json"]
          end
        else
          raise Aws::Errors::EventStreamBuilderError.new(
            "Unsupport eventpayload shape: #{shape.name}")
        end
      end

      def _header_value_type(shape, value)
        case shape
        when StringShape then "string"
        when IntegerShape then "integer"
        when TimestampShape then "timestamp"
        when BlobShape then "bytes"
        when BooleanShape then !!value ? "bool_true" : "bool_false"
        else
          raise Aws::Errors::EventStreamBuilderError.new(
            "Unsupported eventheader shape: #{shape.name}")
        end
      end

      def _build_payload(streaming, ref, value)
        streaming ? value : @serializer_class.new(ref).serialize(value)
      end

    end
  end
end
