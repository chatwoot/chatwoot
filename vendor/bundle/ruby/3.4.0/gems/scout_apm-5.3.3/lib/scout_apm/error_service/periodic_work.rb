module ScoutApm
  module ErrorService
    class PeriodicWork
      attr_reader :context

      def initialize(context)
        @context = context
        @notifier = ScoutApm::ErrorService::Notifier.new(context)
      end

      # Expected to be called many times over the life of the agent
      def run
        @notifier.ship
      end
    end
  end
end
