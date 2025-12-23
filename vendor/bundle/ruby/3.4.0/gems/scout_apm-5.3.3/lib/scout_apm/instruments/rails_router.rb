module ScoutApm
  module Instruments
    class RailsRouter
      attr_reader :context

      def initialize(context)
        @context = context
        @installed = false
      end

      def logger
        context.logger
      end

      def installed?
        @installed
      end

      def install(prepend:)
        if defined?(ActionDispatch) && defined?(ActionDispatch::Routing) && defined?(ActionDispatch::Routing::RouteSet)
          @installed = true

          ActionDispatch::Routing::RouteSet.class_eval do
            def call_with_scout_instruments(*args)
              req = ScoutApm::RequestManager.lookup
              req.start_layer(ScoutApm::Layer.new("Router", "Rails"))

              begin
                call_without_scout_instruments(*args)
              ensure
                req.stop_layer
              end
            end

            alias_method :call_without_scout_instruments, :call
            alias_method :call, :call_with_scout_instruments
          end
        end
      end
    end
  end
end
