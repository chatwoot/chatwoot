module ScoutApm
  module LayerConverters
    class TraceConverter < ConverterBase
      ###################
      #  Converter API  #
      ###################


      def record!
        @points = context.slow_request_policy.score(request)

        # Let the store know we're here, and if it wants our data, it will call
        # back into #call
        @store.track_trace!(self)

        nil # not returning anything in the layer results ... not used
      end

      #####################
      #  ScoreItemSet API #
      #####################
      def name; request.unique_name; end
      def score; @points; end

      # Unconditionally attempts to convert this into a DetailedTrace object.
      # Can return nil if the request didn't have any scope_layer or if `timeline_traces` aren't enabled.
      def call
        return nil unless scope_layer
        return nil unless context.config.value('timeline_traces')

        # Since this request is being stored, update the needed counters
        context.slow_request_policy.stored!(request)

        # record the change in memory usage
        mem_delta = ScoutApm::Instruments::Process::ProcessMemory.new(context).rss_to_mb(@request.capture_mem_delta!)

        transaction_id = request.transaction_id
        revision = context.environment.git_revision.sha
        start_instant = request.root_layer.start_time
        stop_instant = request.root_layer.stop_time
        type = if request.web?
                 "Web"
               elsif request.job?
                 "Job"
               else
                 "Unknown"
               end

        # Create request tags
        #
        tags = {
          :allocations => request.root_layer.total_allocations,
          :mem_delta => mem_delta,
        }.merge(request.context.to_flat_hash)

        host = context.environment.hostname
        path = request.annotations[:uri] || ""
        code = "" # User#index for instance

        spans = create_spans(request.root_layer)
        if limited?
          tags[:"scout.reached_span_cap"] = true
        end

        DetailedTrace.new(
          transaction_id,
          revision,
          host,
          start_instant,
          stop_instant,
          type,

          path,
          code,

          spans,
          tags

          # total_score = 0,
          # percentile_score = 0,
          # age_score = 0,
          # memory_delta_score = 0,
          # memory_allocations_score = 0
        )
      end

      # Returns an array of span objects. Uses recursion to get all children
      # wired up w/ correct parent_ids
      def create_spans(layer, parent_id = nil)
        span_id = ScoutApm::Utils::SpanId.new.to_s

        start_instant = layer.start_time
        stop_instant = layer.stop_time
        operation = layer.legacy_metric_name
        tags = {
          :start_allocations => layer.allocations_start,
          :stop_allocations => layer.allocations_stop,
        }
        if layer.desc
          tags[:desc] = layer.desc.to_s
        end
        if layer.annotations && layer.annotations[:record_count]
          tags["db.record_count"] = layer.annotations[:record_count]
        end
        if layer.annotations && layer.annotations[:class_name]
          tags["db.class_name"] = layer.annotations[:class_name]
        end
        if layer.backtrace
          tags[:backtrace] = backtrace_parser(layer.backtrace) rescue nil
        end

        # Collect up self, and all children into result array
        result = []
        result << DetailedTraceSpan.new(
          span_id.to_s,
          parent_id.to_s,
          start_instant,
          stop_instant,
          operation,
          tags)

        layer.children.each do |child|
          # Don't create spans from limited layers. These don't have start/stop times and our processing can't
          # handle these yet.
          unless over_span_limit?(result) || child.is_a?(LimitedLayer)
            result += create_spans(child, span_id)
          end
        end

        return result
      end

      # Take an array of ruby backtrace lines and split it into an array of hashes like:
      # ["/Users/cschneid/.rvm/rubies/ruby-2.2.7/lib/ruby/2.2.0/irb/workspace.rb:86:in `eval'", ...]
      #    turns into:
      # [ {
      #     "file": "app/controllers/users_controller.rb",
      #     "line": 10,
      #     "function": "index"
      # },
      # ]
      def backtrace_parser(lines)
        bt = ScoutApm::Utils::BacktraceParser.new(lines).call

        bt.map do |line|
          match = line.match(/(.*):(\d+):in `(.*)'/)
          {
            "file" => match[1],
            "line" => match[2],
            "function" => match[3],
          }
        end

      end

      ################################################################################
      # Limit Handling
      ################################################################################

      # To prevent huge traces from being generated, we stop collecting
      # spans as we go beyond some reasonably large count.
      MAX_SPANS = 1500

      def over_span_limit?(spans)
        if spans.size > MAX_SPANS
          log_over_span_limit
          @limited = true
        else
          false
        end
      end

      def log_over_span_limit
        unless limited?
          context.logger.debug "Not recording additional spans for #{name}. Over the span limit."
        end
      end

      def limited?
        !! @limited
      end
    end
  end
end
