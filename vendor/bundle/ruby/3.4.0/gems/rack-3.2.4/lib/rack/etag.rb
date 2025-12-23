# frozen_string_literal: true

require 'digest/sha2'

require_relative 'constants'
require_relative 'utils'

module Rack
  # Automatically sets the etag header on all String bodies.
  #
  # The etag header is skipped if etag or last-modified headers are sent or if
  # a sendfile body (body.responds_to :to_path) is given (since such cases
  # should be handled by apache/nginx).
  #
  # On initialization, you can pass two parameters: a cache-control directive
  # used when etag is absent and a directive when it is present. The first
  # defaults to nil, while the second defaults to "max-age=0, private, must-revalidate"
  class ETag
    ETAG_STRING = Rack::ETAG
    DEFAULT_CACHE_CONTROL = "max-age=0, private, must-revalidate"

    def initialize(app, no_cache_control = nil, cache_control = DEFAULT_CACHE_CONTROL)
      @app = app
      @cache_control = cache_control
      @no_cache_control = no_cache_control
    end

    def call(env)
      status, headers, body = response = @app.call(env)

      if etag_status?(status) && body.respond_to?(:to_ary) && !skip_caching?(headers)
        body = body.to_ary
        digest = digest_body(body)
        headers[ETAG_STRING] = %(W/"#{digest}") if digest

        # Body was modified, so we need to re-assign it:
        response[2] = body
      end

      unless headers[CACHE_CONTROL]
        if digest
          headers[CACHE_CONTROL] = @cache_control if @cache_control
        else
          headers[CACHE_CONTROL] = @no_cache_control if @no_cache_control
        end
      end

      response
    end

    private

      def etag_status?(status)
        status == 200 || status == 201
      end

      def skip_caching?(headers)
        headers.key?(ETAG_STRING) || headers.key?('last-modified')
      end

      def digest_body(body)
        digest = nil

        body.each do |part|
          (digest ||= Digest::SHA256.new) << part unless part.empty?
        end

        digest && digest.hexdigest.byteslice(0,32)
      end
  end
end
