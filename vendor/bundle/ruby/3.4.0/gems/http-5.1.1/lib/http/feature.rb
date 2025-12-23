# frozen_string_literal: true

module HTTP
  class Feature
    def initialize(opts = {})
      @opts = opts
    end

    def wrap_request(request)
      request
    end

    def wrap_response(response)
      response
    end

    def on_error(request, error); end
  end
end

require "http/features/auto_inflate"
require "http/features/auto_deflate"
require "http/features/logging"
require "http/features/instrumentation"
require "http/features/normalize_uri"
