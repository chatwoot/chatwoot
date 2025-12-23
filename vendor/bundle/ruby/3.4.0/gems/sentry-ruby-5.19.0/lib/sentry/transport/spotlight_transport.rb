# frozen_string_literal: true

require "net/http"
require "zlib"

module Sentry
  # Designed to just report events to Spotlight in development.
  class SpotlightTransport < HTTPTransport
    DEFAULT_SIDECAR_URL = "http://localhost:8969/stream"
    MAX_FAILED_REQUESTS = 3

    def initialize(configuration)
      super
      @sidecar_url = configuration.spotlight.is_a?(String) ? configuration.spotlight : DEFAULT_SIDECAR_URL
      @failed = 0
      @logged = false

      log_debug("[Spotlight] initialized for url #{@sidecar_url}")
    end

    def endpoint
      "/stream"
    end

    def send_data(data)
      if @failed >= MAX_FAILED_REQUESTS
        unless @logged
          log_debug("[Spotlight] disabling because of too many request failures")
          @logged = true
        end

        return
      end

      super
    end

    def on_error
      @failed += 1
    end

    # Similar to HTTPTransport connection, but does not support Proxy and SSL
    def conn
      sidecar = URI(@sidecar_url)
      connection = ::Net::HTTP.new(sidecar.hostname, sidecar.port, nil)
      connection.use_ssl = false
      connection
    end
  end
end
