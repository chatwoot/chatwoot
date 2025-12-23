# A TrackedRequest is a stack of layers, where completed layers (go into, then
# come out of a layer) are forgotten as they finish. Layers are attached to
# their children as the process goes, building a tree structure within the
# layer objects. When the last layer is finished (hence the whole request is
# finished) it hands the root layer off to be recorded.

module ScoutApm
  class TrackedRequest
    # Context is application defined extra information.  (ie, which user, what
    # is their email/ip, what plan are they on, what locale are they using,
    # etc) See documentation for examples on how to set this from a
    # before_filter
    attr_reader :context

    # The first layer registered with this request. All other layers will be
    # children of this layer.
    attr_reader :root_layer

    # As we go through a request, instrumentation can mark more general data into the Request
    # Known Keys:
    #   :uri - the full URI requested by the user
    #   :queue_latency - how long a background Job spent in the queue before starting processing
    attr_reader :annotations

    # Headers as recorded by rails
    # Can be nil if we never reach a Rails Controller
    attr_reader :headers

    # This maintains a lookup hash of Layer names and call counts. It's used to trigger fetching a backtrace on n+1 calls.
    # Note that layer names might not be Strings - can alse be Utils::ActiveRecordMetricName. Also, this would fail for layers
    # with same names across multiple types.
    attr_accessor :call_counts

    # if there's an instant_key, pass the transaction trace on for immediate reporting (in addition to the usual background aggregation)
    # this is set in the controller instumentation (ActionControllerRails3Rails4 according)
    attr_accessor :instant_key

    # An object that responds to `record!(TrackedRequest)` to store this tracked request
    attr_reader :recorder

    # If specified, an override for the name of the request. If unspecified,
    # the name is determined from the name of the Controller or Job layer.
    attr_accessor :name_override

    # A unique, but otherwise meaningless String to identify this request. UUID
    attr_reader :transaction_id

    # When we see these layers, it means a real request is going through the
    # system. We toggle a flag to turn on some slightly more expensive
    # instrumentation (backtrace collection and the like) that would be too
    # expensive in situations where the framework is constantly churning. We
    # see that on Sidekiq.
    REQUEST_TYPES = ["Controller", "Job"]

    # Layers of type 'AutoInstrument' are not recorded if their total_call_time doesn't exceed this threshold.
    # AutoInstrument layers are frequently of short duration. This throws out this deadweight that is unlikely to be optimized.
    AUTO_INSTRUMENT_TIMING_THRESHOLD = 5/1_000.0 # units = seconds

    def initialize(agent_context, store)
      @agent_context = agent_context
      @store = store #this is passed in so we can use a real store (normal operation) or fake store (instant mode only)
      @layers = []
      @call_set = Hash.new { |h, k| h[k] = CallSet.new }
      @annotations = {}
      @ignoring_children = 0
      @context = Context.new(agent_context)
      @root_layer = nil
      @error = false
      @stopping = false
      @instant_key = nil
      @mem_start = mem_usage
      @recorder = agent_context.recorder
      @real_request = false
      @transaction_id = ScoutApm::Utils::TransactionId.new.to_s
      ignore_request! if @recorder.nil?
    end

    def start_layer(layer)
      # If we're already stopping, don't do additional layers
      return if stopping?

      return if ignoring_children?

      return ignoring_start_layer if ignoring_request?

      start_request(layer) unless @root_layer

      if REQUEST_TYPES.include?(layer.type)
        real_request!
      end
      @layers.push(layer)
    end

    def stop_layer
      # If we're already stopping, don't do additional layers
      return if stopping?

      return if ignoring_children?

      return ignoring_stop_layer if ignoring_request?

      layer = @layers.pop

      # Safeguard against a mismatch in the layer tracking in an instrument.
      # This class works under the assumption that start & stop layers are
      # lined up correctly. If stop_layer gets called twice, when it should
      # only have been called once you'll end up with this error.
      if layer.nil?
        logger.warn("Error stopping layer, was nil. Root Layer: #{@root_layer.inspect}")
        stop_request
        return
      end

      layer.record_stop_time!
      layer.record_allocations!

      # Must follow layer.record_stop_time! as the total_call_time is used to determine if the layer is significant.
      return if layer_insignificant?(layer)

      # Check that the parent exists before calling a method on it, since some threading can get us into a weird state.
      # this doesn't fix that state, but prevents exceptions from leaking out.
      parent = @layers[-1]
      if parent
        parent.add_child(layer)
      end

      # This must be called before checking if a backtrace should be collected as the call count influences our capture logic.
      # We call `#update_call_counts in stop layer to ensure the layer has a final desc. Layer#desc is updated during the AR instrumentation flow.
      update_call_counts!(layer)
      if capture_backtrace?(layer)
        layer.capture_backtrace!
      end


      if finalized?
        stop_request
      end
    end

    def real_request!
      @real_request = true
    end

    # Have we seen a "controller" or "job" layer so far?
    def real_request?
      @real_request
    end

    # Grab the currently running layer. Useful for adding additional data as we
    # learn it. This is useful in ActiveRecord instruments, where we start the
    # instrumentation early, and gradually learn more about the request that
    # actually happened as we go (for instance, the # of records found, or the
    # actual SQL generated).
    #
    # Returns nil in the case there is no current layer. That would be normal
    # for a completed TrackedRequest
    def current_layer
      @layers.last
    end

    BACKTRACE_BLACKLIST = ["Controller", "Job"]
    def capture_backtrace?(layer)
      return if ignoring_request?

      # A backtrace has already been recorded. This happens with autoinstruments as
      # the partial backtrace is set when creating the layer.
      return false if layer.backtrace

      # Never capture backtraces for this kind of layer. The backtrace will
      # always be 100% framework code.
      return false if BACKTRACE_BLACKLIST.include?(layer.type)

      # Only capture backtraces if we're in a real "request". Otherwise we
      # can spend lot of time capturing backtraces from the internals of
      # Sidekiq, only to throw them away immediately.
      return false unless real_request?

      # Capture any individually slow layer.
      return true if layer.total_exclusive_time > backtrace_threshold

      # Capture any layer that we've seen many times. Captures n+1 problems
      return true if @call_set[layer.name].capture_backtrace?

      # Don't capture otherwise
      false
    end

    # Returns +true+ if the total call time of AutoInstrument layers exceeds +AUTO_INSTRUMENT_TIMING_THRESHOLD+ and
    # records a Histogram of insignificant / significant layers by file name.
    def layer_insignificant?(layer)
      result = false # default is significant
      if layer.type == 'AutoInstrument'
        if layer.total_call_time < AUTO_INSTRUMENT_TIMING_THRESHOLD
          result = true # not significant
        end
        # 0 = not significant, 1 = significant
        @agent_context.auto_instruments_layer_histograms.add(layer.file_name, (result ? 0 : 1))
      end
      result
    end

    # Maintains a lookup Hash of call counts by layer name. Used to determine if we should capture a backtrace.
    def update_call_counts!(layer)
      @call_set[layer.name].update!(layer.desc)
    end

    # Grab backtraces more aggressively when running in dev trace mode
    def backtrace_threshold
      @agent_context.dev_trace_enabled? ? 0.05 : 0.5 # the minimum threshold in seconds to record the backtrace for a metric.
    end

    # This may be in bytes or KB based on the OSX. We store this as-is here and only do conversion to MB in Layer Converters.
    # XXX: Move this to environment?
    def mem_usage
      ScoutApm::Instruments::Process::ProcessMemory.new(@agent_context).rss
    end

    def capture_mem_delta!
      @mem_delta = mem_usage - @mem_start
    end

    ###################################
    # Request Lifecycle
    ###################################

    # Are we finished with this request?
    # We're done if we have no layers left after popping one off
    def finalized?
      @layers.none?
    end

    # Run at the beginning of the whole request
    #
    # * Capture the first layer as the root_layer
    def start_request(layer)
      @root_layer = layer unless @root_layer # capture root layer
    end

    # Run at the end of the whole request
    #
    # * Send the request off to be stored
    def stop_request
      @stopping = true

      if @recorder
        @recorder.record!(self)
      end
    end

    def stopping?
      @stopping
    end

    ###################################
    # Annotations
    ###################################

    # As we learn things about this request, we can add data here.
    # For instance, when we know where Rails routed this request to, we can store that scope info.
    # Or as soon as we know which URI it was directed at, we can store that.
    #
    # This data is internal to ScoutApm, to add custom information, use the Context api.
    def annotate_request(hsh)
      @annotations.merge!(hsh)
    end

    # This request had an exception.  Mark it down as an error
    def error!
      @error = true
    end

    def error?
      @error
    end

    def set_headers(headers)
      @headers = headers
    end

    def instant?
      return false if ignoring_request?

      instant_key
    end

    ###################################
    # Persist the Request
    ###################################

    def recorded!
      @recorded = true
    end

    # Convert this request to the appropriate structure, then report it into
    # the peristent Store object
    def record!
      recorded!

      return if ignoring_request?

      # If we didn't have store, but we're trying to record anyway, go
      # figure that out. (this happens in Remote Agent scenarios)
      restore_from_dump! if @agent_context.nil?

      # Bail out early if the user asked us to ignore this uri
      return if @agent_context.ignored_uris.ignore?(annotations[:uri])

      apply_name_override

      @agent_context.transaction_time_consumed.add(unique_name, root_layer.total_call_time)

      context.add(:transaction_id => transaction_id)

      # Make a constant, then call converters.dup.each so it isn't inline?
      converters = {
        :histograms => LayerConverters::Histograms,
        :metrics => LayerConverters::MetricConverter,
        :errors => LayerConverters::ErrorConverter,
        :allocation_metrics => LayerConverters::AllocationMetricConverter,
        :queue_time => LayerConverters::RequestQueueTimeConverter,
        :job => LayerConverters::JobConverter,
        :db => LayerConverters::DatabaseConverter,
        :external_service => LayerConverters::ExternalServiceConverter,

        :slow_job => LayerConverters::SlowJobConverter,
        :slow_req => LayerConverters::SlowRequestConverter,

        # This is now integrated into the slow_job and slow_req converters, so that
        # we get the exact same set of traces either way. We can call it
        # directly when we move away from the legacy trace styles.
        # :traces => LayerConverters::TraceConverter,
      }

      walker = LayerConverters::DepthFirstWalker.new(self.root_layer)
      converter_instances = converters.inject({}) do |memo, (slug, klass)|
        instance = klass.new(@agent_context, self, layer_finder, @store)
        instance.register_hooks(walker)
        memo[slug] = instance
        memo
      end
      walker.walk
      converter_results = converter_instances.inject({}) do |memo, (slug,i)|
        memo[slug] = i.record!
        memo
      end

      @agent_context.extensions.run_transaction_callbacks(converter_results,context,layer_finder.scope)

      # If there's an instant_key, it means we need to report this right away
      if web? && instant?
        converter = converters.find{|c| c.class == LayerConverters::SlowRequestConverter}
        trace = converter.call
        ScoutApm::InstantReporting.new(trace, instant_key).call
      end

      if web? || job?
        ensure_background_worker
      end
    end

    # This request is a job transaction iff it has a 'Job' layer
    # Use this only during recording
    def job?
      layer_finder.job != nil
    end

    # This request is a web transaction iff it has a 'Controller' layer
    # Use this only during recording
    def web?
      layer_finder.controller != nil
    end


    def layer_finder
      @layer_finder ||= LayerConverters::FindLayerByType.new(self)
    end

    # Ensure the background worker thread is up & running - a fallback if other
    # detection doesn't achieve this at boot.
    def ensure_background_worker
      agent = ScoutApm::Agent.instance
      agent.start
    rescue => e
      true
    end


    # Only call this after the request is complete
    def unique_name
      return nil if ignoring_request?

      @unique_name ||= begin
                         scope_layer = LayerConverters::FindLayerByType.new(self).scope
                         if scope_layer
                           scope_layer.legacy_metric_name
                         else
                           :unknown
                         end
                       end
    end

    # Have we already persisted this request?
    # Used to know when we should just create a new one (don't attempt to add
    # data to an already-recorded request). See RequestManager
    def recorded?
      return ignoring_recorded? if ignoring_request?

      @recorded
    end

    ###################################
    # Ignoring Children
    ###################################

    # Enable this when you would otherwise double track something interesting.
    # This came up when we implemented InfluxDB instrumentation, which is more
    # specific, and useful than the fact that InfluxDB happens to use Net::HTTP
    # internally
    #
    # When enabled, new layers won't be added to the current Request, and calls
    # to stop_layer will be ignored.
    #
    # Do not forget to turn if off when leaving a layer, it is the
    # instrumentation's task to do that.
    #
    # When you use this in code, be sure to use it in this order:
    #
    # start_layer
    # ignore_children
    #  -> call
    # acknowledge_children
    # stop_layer
    #
    # If you don't call it in this order, it's possible to get out of sync, and
    # have an ignored start and an actually-executed stop, causing layers to
    # get out of sync

    def ignore_children!
      @ignoring_children += 1
    end

    def acknowledge_children!
      if @ignoring_children > 0
        @ignoring_children -= 1
      end
    end

    def ignoring_children?
      @ignoring_children > 0
    end

    ################################################################################
    # Ignoring the rest of a request
    ################################################################################

    # At any point in the request, calling code or instrumentation can call
    # `ignore_request!` to immediately stop recording any information about new
    # layers, and delete any existing layer info.  This class will still exist,
    # and respond to methods as normal, but `record!` won't be called, and no
    # data will be recorded.
    #
    # We still need to keep track of the current layer depth (via
    # @ignoring_depth counter) so we know when to report that the class was
    # "reported", and ready to be recreated for the next request.

    def ignore_request!
      return if @ignoring_request

      # Set instance variable
      @ignoring_request = true

      # Store data we'll need
      @ignoring_depth = @layers.length

      # Clear data
      @layers = []
      @root_layer = nil
      @call_set = nil
      @annotations = {}
      @instant_key = nil
    end

    def ignoring_request?
      @ignoring_request
    end

    def ignoring_start_layer
      @ignoring_depth += 1
    end

    def ignoring_stop_layer
      @ignoring_depth -= 1
    end

    def ignoring_recorded?
      @ignoring_depth <= 0
    end

    def logger
      @agent_context.logger
    end

    ###########################
    #  Serialization Helpers
    ###########################

    # Actually go fetch & make-real any lazily created data.
    # Clean up any cleverness in objects.
    # Makes this object ready to be Marshal Dumped (or otherwise serialized)
    def prepare_to_dump!
      @call_set = nil
      @store = nil
      @recorder = nil
      @agent_context = nil
    end

    # Go re-fetch the store based on what the Agent's official one is. Used
    # after hydrating a dumped TrackedRequest
    def restore_from_dump!
      @agent_context = ScoutApm::Agent.instance.context
      @recorder = @agent_context.recorder
      @store = @agent_context.store
    end

    private

    def apply_name_override
      return unless name_override

      scope_layer = layer_finder.scope
      if scope_layer
        scope_layer.name = name_override
      end
    end
  end
end
