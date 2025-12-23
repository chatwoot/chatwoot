# Uses a different workflow than normal metrics. We ignore the shared walk of
# the layer tree, and instead wait until we're sure we even want to do any
# work. Only then do we go realize all the SlowJobRecord & metrics associated.
#
module ScoutApm
  module LayerConverters
    class SlowJobConverter < ConverterBase
      ###################
      #  Converter API  #
      ###################
      def record!
        return nil unless request.job?
        @points = context.slow_job_policy.score(request)

        # Let the store know we're here, and if it wants our data, it will call
        # back into #call
        @store.track_slow_job!(self)

        nil # not returning anything in the layer results ... not used
      end

      #####################
      #  ScoreItemSet API #
      #####################
      def name; request.unique_name; end
      def score; @points; end

      # Called by the set to force this to actually be created.
      def call
        return nil unless request.job?
        return nil unless layer_finder.queue
        return nil unless layer_finder.job

        context.slow_job_policy.stored!(request)

        # record the change in memory usage
        mem_delta = ScoutApm::Instruments::Process::ProcessMemory.new(context).rss_to_mb(request.capture_mem_delta!)

        timing_metrics, allocation_metrics = create_metrics

        unless ScoutApm::Instruments::Allocations::ENABLED
          allocation_metrics = {}
        end

        SlowJobRecord.new(
          context,
          queue_layer.name,
          job_layer.name,
          root_layer.stop_time,
          job_layer.total_call_time,
          job_layer.total_exclusive_time,
          request.context,
          timing_metrics,
          allocation_metrics,
          mem_delta,
          job_layer.total_allocations,
          score,
          limited?,
          span_trace
        )
      end

      def create_metrics
        # Create a new walker, and wire up the subscope stuff
        walker = LayerConverters::DepthFirstWalker.new(self.root_layer)
        register_hooks(walker)

        metric_hash = Hash.new
        allocation_metric_hash = Hash.new

        walker.on do |layer|
          next if skip_layer?(layer)

          # The queue_layer is useful to capture for other reasons, but doesn't
          # create a MetricMeta/Stat of its own
          next if layer == queue_layer

          store_specific_metric(layer, metric_hash, allocation_metric_hash)
          store_aggregate_metric(layer, metric_hash, allocation_metric_hash)
        end

        # And now run through the walk we just defined
        walker.walk

        metric_hash = attach_backtraces(metric_hash)
        allocation_metric_hash = attach_backtraces(allocation_metric_hash)

        [metric_hash, allocation_metric_hash]
      end

      def skip_layer?(layer); super(layer) || layer == queue_layer; end
      def queue_layer; layer_finder.queue; end
      def job_layer; layer_finder.job; end

      def span_trace
        ScoutApm::LayerConverters::TraceConverter.
          new(@context, @request, @layer_finder, @store).
          call
      end
    end
  end
end
