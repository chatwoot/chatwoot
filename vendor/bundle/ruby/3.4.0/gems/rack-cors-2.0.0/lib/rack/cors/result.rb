# frozen_string_literal: true

module Rack
  class Cors
    class Result
      HEADER_KEY = 'x-rack-cors'

      MISS_NO_ORIGIN = 'no-origin'
      MISS_NO_PATH   = 'no-path'

      MISS_NO_METHOD   = 'no-method'
      MISS_DENY_METHOD = 'deny-method'
      MISS_DENY_HEADER = 'deny-header'

      attr_accessor :preflight, :hit, :miss_reason

      def hit?
        !!hit
      end

      def preflight?
        !!preflight
      end

      def miss(reason)
        self.hit = false
        self.miss_reason = reason
      end

      def self.hit(env)
        r = Result.new
        r.preflight = false
        r.hit = true
        env[Rack::Cors::ENV_KEY] = r
      end

      def self.miss(env, reason)
        r = Result.new
        r.preflight = false
        r.hit = false
        r.miss_reason = reason
        env[Rack::Cors::ENV_KEY] = r
      end

      def self.preflight(env)
        r = Result.new
        r.preflight = true
        env[Rack::Cors::ENV_KEY] = r
      end

      def append_header(headers)
        headers[HEADER_KEY] = if hit?
                                preflight? ? 'preflight-hit' : 'hit'
                              else
                                [
                                  (preflight? ? 'preflight-miss' : 'miss'),
                                  miss_reason
                                ].join('; ')
                              end
      end
    end
  end
end
