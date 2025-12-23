# frozen_string_literal: true

require_relative '../../../core/header_collection'

module Datadog
  module Tracing
    module Contrib
      module Rack
        # Classes and utilities for handling headers in Rack.
        module Header
          # An implementation of a header collection that looks up headers from a Rack environment.
          class RequestHeaderCollection < Datadog::Core::HeaderCollection
            # Creates a header collection from a rack environment.
            def initialize(env)
              super()
              @env = env
            end

            # Gets the value of the header with the given name.
            def get(header_name)
              @env[Header.to_rack_header(header_name)]
            end

            # Allows this class to have a similar API to a {Hash}.
            alias [] get

            # Tests whether a header with the given name exists in the environment.
            def key?(header_name)
              @env.key?(Header.to_rack_header(header_name))
            end
          end

          def self.to_rack_header(name)
            key = name.to_s.upcase.gsub(/[-\s]/, '_')
            case key
            when 'CONTENT_TYPE', 'CONTENT_LENGTH'
              # NOTE: The Rack spec says:
              # > The environment must not contain the keys HTTP_CONTENT_TYPE or HTTP_CONTENT_LENGTH
              # > (use the versions without HTTP_).
              # See https://github.com/rack/rack/blob/e217a399eb116362710aac7c5b8dc691ea2189b3/SPEC.rdoc?plain=1#L119-L121
              key
            else
              "HTTP_#{key}"
            end
          end
        end
      end
    end
  end
end
