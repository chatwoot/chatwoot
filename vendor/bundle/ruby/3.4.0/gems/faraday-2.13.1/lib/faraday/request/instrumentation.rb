# frozen_string_literal: true

module Faraday
  class Request
    # Middleware for instrumenting Requests.
    class Instrumentation < Faraday::Middleware
      # Options class used in Request::Instrumentation class.
      Options = Faraday::Options.new(:name, :instrumenter) do
        remove_method :name
        # @return [String]
        def name
          self[:name] ||= 'request.faraday'
        end

        remove_method :instrumenter
        # @return [Class]
        def instrumenter
          self[:instrumenter] ||= ActiveSupport::Notifications
        end
      end

      # Instruments requests using Active Support.
      #
      # Measures time spent only for synchronous requests.
      #
      # @example Using ActiveSupport::Notifications to measure time spent
      #   for Faraday requests.
      #   ActiveSupport::Notifications
      #     .subscribe('request.faraday') do |name, starts, ends, _, env|
      #     url = env[:url]
      #     http_method = env[:method].to_s.upcase
      #     duration = ends - starts
      #     $stderr.puts '[%s] %s %s (%.3f s)' %
      #       [url.host, http_method, url.request_uri, duration]
      #   end
      # @param app [#call]
      # @param options [nil, Hash] Options hash
      # @option options [String] :name ('request.faraday')
      #   Name of the instrumenter
      # @option options [Class] :instrumenter (ActiveSupport::Notifications)
      #   Active Support instrumenter class.
      def initialize(app, options = nil)
        super(app)
        @name, @instrumenter = Options.from(options)
                                      .values_at(:name, :instrumenter)
      end

      # @param env [Faraday::Env]
      def call(env)
        @instrumenter.instrument(@name, env) do
          @app.call(env)
        end
      end
    end
  end
end

Faraday::Request.register_middleware(instrumentation: Faraday::Request::Instrumentation)
