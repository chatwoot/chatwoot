# frozen_string_literal: true

module Datadog
  module Tracing
    module Configuration
      module HTTP
        # Datadog tracing supports capturing HTTP request and response headers as span tags.
        #
        # The provided configuration String for this feature has to be pre-processed to
        # allow for ease of utilization by each HTTP integration.
        #
        # This class process configuration, stores the result, and provides methods to
        # utilize this configuration.
        class HeaderTags
          # @param header_tags [Array<String>] The list of strings from DD_TRACE_HEADER_TAGS.
          def initialize(header_tags)
            @request_headers = {}
            @response_headers = {}
            @header_tags = header_tags

            @header_tags.each do |header_tag|
              header, tag = header_tag.split(':', 2)

              next unless header # Empty string guard

              if tag && !tag.empty?
                # When a custom tag name is provided, use that name for both
                # request and response tags.
                normalized_tag = Tracing::Metadata::Ext::HTTP::Headers.to_tag(tag, allow_nested: true)
                request = response = normalized_tag
              else
                # Otherwise, use our internal pattern of
                # "http.{request|response}.headers.{header}" as tag name.
                request = Tracing::Metadata::Ext::HTTP::RequestHeaders.to_tag(header)
                response = Tracing::Metadata::Ext::HTTP::ResponseHeaders.to_tag(header)
              end

              @request_headers[header] = request
              @response_headers[header] = response
            end
          end

          # Receives a case insensitive hash with the request headers and returns
          # a list of tag names and values that can be set in a span.
          def request_tags(headers)
            @request_headers.map do |header_name, span_tag|
              # Case-insensitive search
              header_value = headers[header_name]

              [span_tag, header_value] if header_value
            end.compact
          end

          # Receives a case insensitive hash with the response headers and returns
          # a list of tag names and values that can be set in a span.
          def response_tags(headers)
            @response_headers.map do |header_name, span_tag|
              # Case-insensitive search
              header_value = headers[header_name]

              [span_tag, header_value] if header_value
            end.compact
          end

          # For easy configuration inspection,
          # print the original configuration setting.
          def to_s
            @header_tags.join(',').to_s
          end
        end
      end
    end
  end
end
