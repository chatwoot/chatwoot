# frozen_string_literal: true

module Rack
  # Installs signal handlers that are safely processed after a request
  #
  # NOTE: This middleware should not be used in a threaded environment
  #
  # use Rack::Signals.new do
  #   trap 'INT', lambda {
  #     puts "Exiting now"
  #     exit
  #   }
  #
  #   trap_when_ready 'USR1', lambda {
  #     puts "Exiting when ready"
  #     exit
  #   }
  # end
  class Signals
    class BodyWithCallback
      def initialize(body, callback)
        @body, @callback = body, callback
      end

      def each(&block)
        @body.each(&block)
        @callback.call
      end

      def close
        @body.close if @body.respond_to?(:close)
      end
    end

    def initialize(app, &block)
      @app = app
      @processing = false
      @when_ready = nil
      instance_eval(&block)
    end

    def call(env)
      begin
        @processing, @when_ready = true, nil
        status, headers, body = @app.call(env)

        if handler = @when_ready
          body = BodyWithCallback.new(body, handler)
          @when_ready = nil
        end
      ensure
        @processing = false
      end

      [status, headers, body]
    end

    def trap_when_ready(signal, handler)
      when_ready_handler = lambda { |signal|
        if @processing
          @when_ready = lambda { handler.call(signal) }
        else
          handler.call(signal)
        end
      }
      trap(signal, when_ready_handler)
    end
  end
end
