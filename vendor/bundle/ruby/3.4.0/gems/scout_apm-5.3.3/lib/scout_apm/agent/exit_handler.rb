module ScoutApm
  class Agent
    class ExitHandler
      attr_reader :context

      def initialize(context)
        @context = context
      end

      def install
        logger.debug "Shutdown handler not supported" and return unless exit_handler_supported?
        logger.debug "Installing Shutdown Handler"

        at_exit do
          logger.info "Shutting down Scout Agent"
          # MRI 1.9 bug drops exit codes.
          # http://bugs.ruby-lang.org/issues/5218
          if environment.ruby_19?
            status = $!.status if $!.is_a?(SystemExit)
            shutdown
            exit status if status
          else
            shutdown
          end
        end
      end

      private

      # Called via the at_exit handler, it:
      # (1) Stops the background worker
      # (2) Stores metrics locally (forcing current-minute metrics to be written)
      # It does not attempt to actually report metrics.
      def shutdown
        logger.info "Shutting down ScoutApm"
        return if !context.started?
        context.shutting_down!
        ::ScoutApm::Agent.instance.stop_background_worker
      end

      def exit_handler_supported?
        if environment.sinatra?
          logger.debug "Exit handler not supported for Sinatra"
          false
        elsif environment.jruby?
          logger.debug "Exit handler not supported for JRuby"
          false
        elsif environment.rubinius?
          logger.debug "Exit handler not supported for Rubinius"
          false
        else
          true
        end
      end

      def logger
        context.logger
      end

      def environment
        context.environment
      end
    end
  end
end
