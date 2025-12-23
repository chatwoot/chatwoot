module ScoutApm
  module Extensions
    # A +TransactionCallbackPayload+ is passed to each Transaction callback's +call+ method. 
    # It encapsulates the data about a specific transaction.
    class TransactionCallbackPayload
      # A Hash that stores the output of each layer converter by name. See the naming conventions in +TrackedRequest+.
      attr_accessor :converter_results

      def initialize(agent_context,converter_results,context,scope_layer)
        @agent_context = agent_context
        @converter_results = converter_results
        @context = context
        @scope_layer = scope_layer
      end

      # A flat hash of the context associated w/this transaction (ie user ip and another other data added to context).
      def context
        @context.to_flat_hash
      end

      # The total duration of the transaction
      def duration_ms
        @scope_layer.total_call_time*1000 # ms
      end

      # The time in queue of the transaction in ms. If not present, +nil+ is returned as this is unknown.
      def queue_time_ms
        # Controller logic
        if converter_results[:queue_time] && converter_results[:queue_time].any?
          converter_results[:queue_time].values.first.total_call_time*1000 # ms
        # Job logic
        elsif converter_results[:job]
          stat = converter_results[:job].metric_set.metrics[ScoutApm::MetricMeta.new("Latency/all", :scope => transaction_name)]
          stat ? stat.total_call_time*1000 : nil
        else
          nil
        end
      end

      def hostname
        @agent_context.environment.hostname
      end

      def app_name
        @agent_context.config.value('name')
      end

      # Returns +true+ if the transaction raised an exception.
      def error?
        converter_results[:errors] && converter_results[:errors].any?
      end

      def transation_type
        @scope_layer.type
      end

      def transaction_name
        @scope_layer.legacy_metric_name
      end

      # Web/Job are more language-agnostic names for controller/job. For example, Python Django does not have controllers.
      def transaction_type_slug
        case transation_type
        when 'Controller'
          'web'
        when 'Job'
          'job'
        else
          'transaction'
        end
      end
    end
  end
end