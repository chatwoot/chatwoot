# frozen_string_literal: false

require_relative '../../../distributed/fetcher'

module Datadog
  module Tracing
    module Contrib
      module HTTP
        module Distributed
          # Retrieves HTTP headers from carrier.
          # Headers will also match if Rack-formatted:
          # 'my-header' will match 'my-header' and 'HTTP_MY_HEADER'.
          #
          # In case both variants are present, the verbatim match will be used.
          class Fetcher < Tracing::Distributed::Fetcher
            # @param [String] name the header name
            # @return [String, nil] the header value or nil if not found
            def [](name)
              # Try to fetch with the plain key
              value = super(name)
              return value if value && !value.empty?

              # If not found, try the Rack-formatted key
              rack_header = "HTTP-#{name}"
              rack_header.upcase!
              rack_header.tr!('-'.freeze, '_'.freeze)

              hdr = super(rack_header)

              # Only return the value if it is not an empty string
              hdr if hdr != ''
            end
          end
        end
      end
    end
  end
end
