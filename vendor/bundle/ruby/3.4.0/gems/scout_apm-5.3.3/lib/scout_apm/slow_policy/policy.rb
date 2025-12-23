# Note that this is semi-internal API. You should not need this, and if you do
# we're here to help at support@scoutapm.com. TrackedRequest doesn't change
# often, but we can't promise a perfectly stable API for it either.
module ScoutApm::SlowPolicy
  class Policy
    attr_reader :context

    def initialize(context)
      @context = context
    end

    def call(request)
      raise NotImplementedError
    end

    # Override in subclasses to execute some behavior if the request gets a
    # slot in the ScoredItemSet. Defaults to no-op
    def stored!(request)
    end
  end
end
