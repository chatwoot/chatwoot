# frozen_string_literal: true

module Rack
  class Cors
    class Resource
      class CorsMisconfigurationError < StandardError
        def message
          'Allowing credentials for wildcard origins is insecure.' \
          " Please specify more restrictive origins or set 'credentials' to false in your CORS configuration."
        end
      end
    end
  end
end
