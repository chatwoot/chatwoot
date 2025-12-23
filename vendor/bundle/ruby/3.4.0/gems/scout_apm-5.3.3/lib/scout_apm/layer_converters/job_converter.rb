# Queue/Critical (implicit count)
#   Job/PasswordResetJob Scope=Queue/Critical (implicit count, & total time)
#     JobMetric/Latency 10 Scope=Job/PasswordResetJob
#     ActiveRecord/User/find Scope=Job/PasswordResetJob
#     ActiveRecord/Message/find Scope=Job/PasswordResetJob
#     HTTP/request Scope=Job/PasswordResetJob
#     View/message/text Scope=Job/PasswordResetJob
#       ActiveRecord/Config/find Scope=View/message/text

module ScoutApm
  module LayerConverters
    class JobConverter < ConverterBase
      attr_reader :meta_options

      def register_hooks(walker)
        return unless request.job?

        super

        @metrics = Hash.new
        @meta_options = {:scope => layer_finder.job.legacy_metric_name}

        walker.on do |layer|
          next if layer == layer_finder.job
          next if layer == layer_finder.queue
          next if skip_layer?(layer)

          # we don't need to use the full metric name for scoped metrics as we
          # only display metrics aggregrated by type, just use "ActiveRecord"
          # or similar.
          metric_name = layer.type

          meta = MetricMeta.new(metric_name, meta_options)
          @metrics[meta] ||= MetricStats.new( meta_options.has_key?(:scope) )

          stat = @metrics[meta]
          stat.update!(layer.total_call_time, layer.total_exclusive_time)
        end

      end

      def record!
        return unless request.job?

        errors = request.error? ? 1 : 0
        add_latency_metric!

        record = JobRecord.new(
          layer_finder.queue.name,
          layer_finder.job.name,
          layer_finder.job.total_call_time,
          layer_finder.job.total_exclusive_time,
          errors,
          @metrics
        )

        @store.track_job!(record)
        record  # this result must be returned so it can be accessed by transaction callback extensions
      end

      # This isn't stored as a specific layer, so grabbing it doesn't use the
      # walker callbacks
      def add_latency_metric!
        latency = request.annotations[:queue_latency] || 0
        meta = MetricMeta.new("Latency", meta_options)
        stat = MetricStats.new
        stat.update!(latency)
        @metrics[meta] = stat
      end
    end
  end
end
