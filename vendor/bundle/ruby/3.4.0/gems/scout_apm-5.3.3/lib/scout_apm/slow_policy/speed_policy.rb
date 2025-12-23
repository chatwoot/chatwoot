require 'scout_apm/slow_policy/policy'

module ScoutApm::SlowPolicy
  class SpeedPolicy < Policy
    # Adjust speed points. See the function
    POINT_MULTIPLIER_SPEED = 0.25

    # Time in seconds
    # Logarithm keeps huge times from swamping the other metrics.
    # 1+ is necessary to keep the log function in positive territory.
    def call(request)
      total_time = request.root_layer.total_call_time
      Math.log(1 + total_time) * POINT_MULTIPLIER_SPEED
    end
  end
end
