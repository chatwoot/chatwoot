# Long running class that determines if, and in how much detail a potentially
# slow transaction should be recorded in

module ScoutApm
  class SlowRequestPolicy
    # The AgentContext we're running in
    attr_reader :context
    attr_reader :policies

    def initialize(context)
      @context = context
      @policies = []
    end

    def add_default_policies
      add(SlowPolicy::SpeedPolicy.new(context))
      add(SlowPolicy::PercentilePolicy.new(context))
      add(SlowPolicy::AgePolicy.new(context))
      add(SlowPolicy::PercentilePolicy.new(context))
    end

    # policy is an object that behaves like a policy (responds to .call(req) for the score, and .store!(req))
    def add(policy)
      unless policy.respond_to?(:call) && policy.respond_to?(:stored!)
        raise "SlowRequestPolicy must implement policy api call(req) and stored!(req)"
      end

      @policies << policy
    end

    # Determine if this request trace should be fully analyzed by scoring it
    # across several metrics, and then determining if that's good enough to
    # make it into this minute's payload.
    #
    # Due to the combining nature of the agent & layaway file, there's no
    # guarantee that a high scoring local champion will still be a winner when
    # they go up to "regionals" and are compared against the other processes
    # running on a node.
    def score(request)
      unique_name = request.unique_name
      if unique_name == :unknown
        return -1 # A negative score, should never be good enough to store.
      end

      policies.map{ |p| p.call(request) }.sum
    end

    def stored!(request)
      policies.each{ |p| p.stored!(request) }
    end
  end
end
