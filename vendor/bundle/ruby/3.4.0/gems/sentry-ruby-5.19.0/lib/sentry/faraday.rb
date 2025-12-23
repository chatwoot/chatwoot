# frozen_string_literal: true

module Sentry
  module Faraday
    OP_NAME = "http.client"

    module Connection
      # Since there's no way to preconfigure Faraday connections and add our instrumentation
      # by default, we need to extend the connection constructor and do it there
      #
      # @see https://lostisland.github.io/faraday/#/customization/index?id=configuration
      def initialize(url = nil, options = nil)
        super

        # Ensure that we attach instrumentation only if the adapter is not net/http
        # because if is is, then the net/http instrumentation will take care of it
        if builder.adapter.name != "Faraday::Adapter::NetHttp"
          # Make sure that it's going to be the first middleware so that it can capture
          # the entire request processing involving other middlewares
          builder.insert(0, ::Faraday::Request::Instrumentation, name: OP_NAME, instrumenter: Instrumenter.new)
        end
      end
    end

    class Instrumenter
      SPAN_ORIGIN = "auto.http.faraday"
      BREADCRUMB_CATEGORY = "http"

      include Utils::HttpTracing

      def instrument(op_name, env, &block)
        return block.call unless Sentry.initialized?

        Sentry.with_child_span(op: op_name, start_timestamp: Sentry.utc_now.to_f, origin: SPAN_ORIGIN) do |sentry_span|
          request_info = extract_request_info(env)

          if propagate_trace?(request_info[:url])
            set_propagation_headers(env[:request_headers])
          end

          res = block.call
          response_status = res.status

          if record_sentry_breadcrumb?
            record_sentry_breadcrumb(request_info, response_status)
          end

          if sentry_span
            set_span_info(sentry_span, request_info, response_status)
          end

          res
        end
      end

      private

      def extract_request_info(env)
        url = env[:url].scheme + "://" + env[:url].host + env[:url].path
        result = { method: env[:method].to_s.upcase, url: url }

        if Sentry.configuration.send_default_pii
          result[:query] = env[:url].query
          result[:body] = env[:body]
        end

        result
      end
    end
  end
end

Sentry.register_patch(:faraday) do
  if defined?(::Faraday)
    ::Faraday::Connection.prepend(Sentry::Faraday::Connection)
  end
end
