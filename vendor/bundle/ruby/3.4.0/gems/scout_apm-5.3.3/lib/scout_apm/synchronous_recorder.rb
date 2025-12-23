# Provide a synchronous approach to recording TrackedRequests
# Doesn't attempt to background the work, or do it elsewhere. It happens
# inline, in the caller thread right when record! is called

module ScoutApm
  class SynchronousRecorder
    attr_reader :context

    def initialize(context)
      @context = context
    end

    def logger
      context.logger
    end

    def start
      # nothing to do
      self
    end

    def stop
      # nothing to do
    end

    def record!(request)
      request.record!
    end
  end
end
