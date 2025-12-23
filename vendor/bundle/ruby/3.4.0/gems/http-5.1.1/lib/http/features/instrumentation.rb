# frozen_string_literal: true

module HTTP
  module Features
    # Instrument requests and responses. Expects an
    # ActiveSupport::Notifications-compatible instrumenter. Defaults to use a
    # namespace of 'http' which may be overridden with a `:namespace` param.
    # Emits a single event like `"request.{namespace}"`, eg `"request.http"`.
    # Be sure to specify the instrumenter when enabling the feature:
    #
    #    HTTP
    #      .use(instrumentation: {instrumenter: ActiveSupport::Notifications.instrumenter})
    #      .get("https://example.com/")
    #
    # Emits two events on every request:
    #
    #  * `start_request.http` before the request is made, so you can log the reqest being started
    #  * `request.http` after the response is recieved, and contains `start`
    #    and `finish` so the duration of the request can be calculated.
    #
    class Instrumentation < Feature
      attr_reader :instrumenter, :name

      def initialize(instrumenter: NullInstrumenter.new, namespace: "http")
        @instrumenter = instrumenter
        @name = "request.#{namespace}"
      end

      def wrap_request(request)
        # Emit a separate "start" event, so a logger can print the request
        # being run without waiting for a response
        instrumenter.instrument("start_#{name}", :request => request)
        instrumenter.start(name, :request => request)
        request
      end

      def wrap_response(response)
        instrumenter.finish(name, :response => response)
        response
      end

      HTTP::Options.register_feature(:instrumentation, self)

      class NullInstrumenter
        def instrument(name, payload = {})
          start(name, payload)
          begin
            yield payload if block_given?
          ensure
            finish name, payload
          end
        end

        def start(_name, _payload)
          true
        end

        def finish(_name, _payload)
          true
        end
      end
    end
  end
end
