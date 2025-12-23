require 'scout_apm/slow_policy/policy'

module ScoutApm::SlowPolicy
  class PercentPolicy < Policy
    # Points for an endpoint's who's throughput * response time is a large % of
    # overall time spent processing requests
    POINT_MULTIPLIER_PERCENT_TIME = 2.5

    # Of the total time spent handling endpoints in this app, if this endpoint
    # is a higher percent, it should get more points.
    #
    # A: 20 calls @ 100ms each => 2 seconds of total time
    # B: 10 calls @ 100ms each => 1 second of total time
    #
    # Then A is 66% of the total call time
    def call(request) # Scale 0.0 - 1.0
      percent = context.transaction_time_consumed.percent_of_total(request.unique_name)

      percent * POINT_MULTIPLIER_PERCENT_TIME
    end
  end
end
