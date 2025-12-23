require 'scout_apm/slow_policy/policy'

module ScoutApm::SlowPolicy
  class AgePolicy < Policy
    # For each minute we haven't seen an endpoint
    POINT_MULTIPLIER_AGE = 0.25

    # A hash of Endpoint Name to the last time we stored a slow transaction for it.
    #
    # Defaults to a start time that is pretty close to application boot time.
    # So the "age" of an endpoint we've never seen is the time the application
    # has been running.
    attr_reader :last_seen

    def initialize(context)
      super

      zero_time = Time.now
      @last_seen = Hash.new { |h, k| h[k] = zero_time }
    end

    def call(request)
      # How long has it been since we've seen this?
      age = Time.now - last_seen[request.unique_name]

      age / 60.0 * POINT_MULTIPLIER_AGE
    end

    def stored!(request)
      last_seen[request.unique_name] = Time.now
    end
  end
end