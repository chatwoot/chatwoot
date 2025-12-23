# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Rack
        # Matches Rack-style headers with a matcher and sets matching headers into a span.
        module HeaderTagging
          def self.tag_request_headers(span, env, configuration)
            # Wrap env in a case-insensitive Rack-style accessor.
            headers = env.is_a?(Header::RequestHeaderCollection) ? env : Header::RequestHeaderCollection.new(env)

            # Use global DD_TRACE_HEADER_TAGS if integration-level configuration is not provided
            tags = if configuration.using_default?(:headers) && !Datadog.configuration.tracing.using_default?(:header_tags)
                     Datadog.configuration.tracing.header_tags.request_tags(headers)
                   else
                     whitelist = configuration[:headers][:request] || []
                     whitelist.each_with_object({}) do |header, result|
                       header_value = headers.get(header)
                       unless header_value.nil?
                         header_tag = Tracing::Metadata::Ext::HTTP::RequestHeaders.to_tag(header)
                         result[header_tag] = header_value
                       end
                     end
                   end

            span.set_tags(tags)
          end

          def self.tag_response_headers(span, headers, configuration)
            headers = Core::Utils::Hash::CaseInsensitiveWrapper.new(headers) # Make header access case-insensitive

            # Use global DD_TRACE_HEADER_TAGS if integration-level configuration is not provided
            tags = if configuration.using_default?(:headers) && !Datadog.configuration.tracing.using_default?(:header_tags)
                     Datadog.configuration.tracing.header_tags.response_tags(headers)
                   else
                     whitelist = configuration[:headers][:response] || []
                     whitelist.each_with_object({}) do |header, result|
                       header_value = headers[header]

                       next if header_value.nil?

                       header_tag = Tracing::Metadata::Ext::HTTP::ResponseHeaders.to_tag(header)

                       # Maintain the value format between Rack 2 and 3
                       #
                       # Rack 2.x => { 'foo' => 'bar,baz' }
                       # Rack 3.x => { 'foo' => ['bar', 'baz'] }
                       result[header_tag] = if header_value.is_a? Array
                                              header_value.join(',')
                                            else
                                              header_value
                                            end
                     end
                   end

            span.set_tags(tags)
          end
        end
      end
    end
  end
end
