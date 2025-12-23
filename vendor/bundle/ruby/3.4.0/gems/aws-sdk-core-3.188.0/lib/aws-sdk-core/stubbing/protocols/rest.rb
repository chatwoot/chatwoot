# frozen_string_literal: true

require 'aws-eventstream'

module Aws
  module Stubbing
    module Protocols
      class Rest

        include Seahorse::Model::Shapes

        def stub_data(api, operation, data)
          resp = new_http_response
          apply_status_code(operation, resp, data)
          apply_headers(operation, resp, data)
          apply_body(api, operation, resp, data)
          resp
        end

        private

        def new_http_response
          resp = Seahorse::Client::Http::Response.new
          resp.status_code = 200
          resp.headers["x-amzn-RequestId"] = "stubbed-request-id"
          resp
        end

        def apply_status_code(operation, resp, data)
          operation.output.shape.members.each do |member_name, member_ref|
            if member_ref.location == 'statusCode'
              resp.status_code = data[member_name] if data.key?(member_name)
            end
          end
        end

        def apply_headers(operation, resp, data)
          Aws::Rest::Request::Headers.new(operation.output).apply(resp, data)
        end

        def apply_body(api, operation, resp, data)
          resp.body = build_body(api, operation, data)
        end

        def build_body(api, operation, data)
          rules = operation.output
          if head_operation(operation)
            ''
          elsif streaming?(rules)
            data[rules[:payload]]
          elsif rules[:payload]
            body_for(api, operation, rules[:payload_member], data[rules[:payload]])
          else
            filtered = Seahorse::Model::Shapes::ShapeRef.new(
              shape: Seahorse::Model::Shapes::StructureShape.new.tap do |s|
                rules.shape.members.each do |member_name, member_ref|
                  s.add_member(member_name, member_ref) if member_ref.location.nil?
                end
              end
            )
            body_for(api, operation, filtered, data)
          end
        end

        def streaming?(ref)
          if ref[:payload]
            case ref[:payload_member].shape
            when StringShape then true
            when BlobShape then true
            else false
            end
          else
            false
          end
        end

        def head_operation(operation)
          operation.http_method == 'HEAD'
        end

        def eventstream?(rules)
          rules.eventstream
        end

        def encode_eventstream_response(rules, data, builder)
          data.inject('') do |stream, event_data|
            # construct message headers and payload
            opts = {headers: {}}
            case event_data.delete(:message_type)
            when 'event'
              encode_event(opts, rules, event_data, builder)
            when 'error'
              # errors are unmodeled
              encode_error(opts, event_data)
            when 'exception'
              # Pending
              raise 'Stubbing :exception event is not supported'
            end
            [stream, Aws::EventStream::Encoder.new.encode(
              Aws::EventStream::Message.new(opts)
            )].pack('a*a*')
          end
        end

        def encode_error(opts, event_data)
          opts[:headers][':error-message'] = Aws::EventStream::HeaderValue.new(
            value: event_data[:error_message],
            type: 'string'
          )
          opts[:headers][':error-code'] = Aws::EventStream::HeaderValue.new(
            value: event_data[:error_code],
            type: 'string'
          )
          opts[:headers][':message-type'] = Aws::EventStream::HeaderValue.new(
            value: 'error',
            type: 'string'
          )
          opts
        end

        def encode_unknown_event(opts, event_type, event_data)
          # right now h2 events are only rest_json
          opts[:payload] = StringIO.new(Aws::Json.dump(event_data))
          opts[:headers][':event-type'] = Aws::EventStream::HeaderValue.new(
            value: event_type.to_s,
            type: 'string'
          )
          opts[:headers][':message-type'] = Aws::EventStream::HeaderValue.new(
            value: 'event',
            type: 'string'
          )
          opts
        end

        def encode_modeled_event(opts, rules, event_type, event_data, builder)
          event_ref = rules.shape.member(event_type)
          explicit_payload = false
          implicit_payload_members = {}
          event_ref.shape.members.each do |name, ref|
            if ref.eventpayload
              explicit_payload = true
            else
              implicit_payload_members[name] = ref
            end
          end

          if !explicit_payload && !implicit_payload_members.empty?
            unless implicit_payload_members.size > 1
              m_name, _ = implicit_payload_members.first
              value = {}
              value[m_name] = event_data[m_name]
              opts[:payload] = StringIO.new(builder.new(event_ref).serialize(value))
            end
          end

          event_data.each do |k, v|
            member_ref = event_ref.shape.member(k)
            if member_ref.eventheader
              opts[:headers][member_ref.location_name] = Aws::EventStream::HeaderValue.new(
                value: v,
                type: member_ref.eventheader_type
              )
            elsif member_ref.eventpayload
              case member_ref.eventpayload_type
              when 'string'
                opts[:payload] = StringIO.new(v)
              when 'blob'
                opts[:payload] = v
              when 'structure'
                opts[:payload] = StringIO.new(builder.new(member_ref).serialize(v))
              end
            end
          end
          opts[:headers][':event-type'] = Aws::EventStream::HeaderValue.new(
            value: event_ref.location_name,
            type: 'string'
          )
          opts[:headers][':message-type'] = Aws::EventStream::HeaderValue.new(
            value: 'event',
            type: 'string'
          )
          opts
        end

        def encode_event(opts, rules, event_data, builder)
          event_type = event_data.delete(:event_type)

          if rules.shape.member?(event_type)
            encode_modeled_event(opts, rules, event_type, event_data, builder)
          else
            encode_unknown_event(opts, event_type, event_data)
          end
        end

      end
    end
  end
end
