# frozen_string_literal: true

require 'time'
require 'base64'

module Aws
  module Rest
    module Request
      class Headers

        include Seahorse::Model::Shapes

        # @param [Seahorse::Model::ShapeRef] rules
        def initialize(rules)
          @rules = rules
        end

        # @param [Seahorse::Client::Http::Request] http_req
        # @param [Hash] params
        def apply(http_req, params)
          @rules.shape.members.each do |name, ref|
            value = params[name]
            next if value.nil?
            case ref.location
            when 'header' then apply_header_value(http_req.headers, ref, value)
            when 'headers' then apply_header_map(http_req.headers, ref, value)
            end
          end
        end

        private

        def apply_header_value(headers, ref, value)
          value = apply_json_trait(value) if ref['jsonvalue']
          case ref.shape
          when TimestampShape then headers[ref.location_name] = timestamp(ref, value)
          when ListShape then list(headers, ref, value)
          else headers[ref.location_name] = value.to_s
          end
        end

        def timestamp(ref, value)
          case ref['timestampFormat'] || ref.shape['timestampFormat']
          when 'unixTimestamp' then value.to_i
          when 'iso8601' then value.utc.iso8601
          else
            # header default to rfc822
            value.utc.httpdate
          end
        end

        def list(headers, ref, value)
          return if !value || value.empty?
          headers[ref.location_name] = value
            .compact
            .map { |s| Seahorse::Util.escape_header_list_string(s.to_s) }
            .join(',')
        end

        def apply_header_map(headers, ref, values)
          prefix = ref.location_name || ''
          values.each_pair do |name, value|
            headers["#{prefix}#{name}"] = value.to_s
          end
        end

        # With complex headers value in json syntax,
        # base64 encodes value to avoid weird characters
        # causing potential issues in headers
        def apply_json_trait(value)
          Base64.strict_encode64(value)
        end

      end
    end
  end
end
