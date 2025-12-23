module ScoutApm
  module Extensions
    # !!! Extensions are a 0.x level API and breakage is expected as the API is refined.
    # Extensions fan out data collected by the agent to additional services.
    class Config
      attr_reader   :agent_context
      attr_accessor :transaction_callbacks
      attr_accessor :periodic_callbacks

      # Adds a new callback that runs after a transaction completes.
      # These run inline during the request and thus should add minimal overhead. 
      # For example, a transaction callback should NOT make inline HTTP calls to outside services.
      # +callback+ must be an object that respond to a +call(payload)+ method.
      #
      # Example:
      # ScoutApm::Extensions::Config.add_transaction_callback(Proc.new { |payload| puts "Duration: #{payload.duration_ms}" })
      #
      # +payload+ is a +ScoutApm::Extensions::TransactionCallbackPayload+ object.
      def self.add_transaction_callback(callback)
        agent_context.extensions.transaction_callbacks << callback
      end

      # Adds a callback that runs when the per-minute report data is sent to Scout.
      # These run in a background thread so external HTTP calls are OK.
      # +callback+ must be an object that responds to a +call(reporting_period, metadata)+ method.
      # 
      # Example:
      # ScoutApm::Extensions::Config.add_periodic_callback(Proc.new { |reporting_period, metadata| ... })
      def self.add_periodic_callback(callback)
        agent_context.extensions.periodic_callbacks << callback
      end

      def initialize(agent_context)
        @agent_context = agent_context
        @transaction_callbacks = []
        @periodic_callbacks = []
      end

      # Runs each reporting period callback. 
      # Each callback runs inside a begin/rescue block so a broken callback doesn't prevent other
      # callbacks from executing or reporting data from being sent. 
      def run_periodic_callbacks(reporting_period, metadata)
        return unless periodic_callbacks.any?

        periodic_callbacks.each do |callback|
          begin
            callback.call(reporting_period, metadata)
          rescue => e
            logger.warn "Error running reporting callback extension=#{callback}"
            logger.info e.message
            logger.debug e.backtrace
          end
        end
      end

      # Runs each transaction callback.
      # Each callback runs inside a begin/rescue block so a broken callback doesn't prevent other
      # callbacks from executing or the transaction from being recorded. 
      def run_transaction_callbacks(converter_results, context, scope_layer)
        # It looks like layer_finder.scope = nil when a Sidekiq job is retried
        return unless scope_layer
        return unless transaction_callbacks.any?

        payload = ScoutApm::Extensions::TransactionCallbackPayload.new(agent_context,converter_results,context,scope_layer)

        transaction_callbacks.each do |callback|
          begin
            callback.call(payload)
          rescue => e
            logger.warn "Error running transaction callback extension=#{callback}"
            logger.info e.message
            logger.debug e.backtrace
          end
        end
      end

      def self.agent_context
        ScoutApm::Agent.instance.context
      end

      def logger
        agent_context.logger
      end

    end
  end
end