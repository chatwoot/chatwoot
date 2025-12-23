module ScoutApm
  module ServerIntegrations
    class Passenger
      attr_reader :logger

      def initialize(logger)
        @logger = logger
      end

      def name
        :passenger
      end

      def forking?; true; end

      def present?
        (defined?(::Passenger) && defined?(::Passenger::AbstractServer)) || defined?(::PhusionPassenger)
      end

      def install
        logger.info "Installing Passenger worker loop."

        PhusionPassenger.on_event(:starting_worker_process) do |forked|
          logger.debug "Passenger is starting a worker process. Starting worker thread."
          ScoutApm::Agent.instance.start_background_worker
        end

        # The agent's at_exit hook doesn't run when a Passenger process stops.
        # This does run when a process stops.
        PhusionPassenger.on_event(:stopping_worker_process) do
          logger.debug "Passenger is stopping a worker process, shutting down the agent."
          ScoutApm::Agent.instance.stop_background_worker
        end
      end

      def found?
        true
      end
    end
  end
end
