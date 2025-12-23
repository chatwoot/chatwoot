require 'scout_apm/slow_policy/policy'

module ScoutApm::SlowPolicy
  class PercentilePolicy < Policy
    def call(request)
      # What approximate percentile was this request?
      total_time = request.root_layer.total_call_time
      percentile = context.request_histograms.approximate_quantile_of_value(request.unique_name, total_time)

      if percentile < 40
        0.4 # Don't put much emphasis on capturing low percentiles.
      elsif percentile < 60
        1.4 # Highest here to get mean traces
      elsif percentile < 90
        0.7 # Between 60 & 90% is fine.
      elsif percentile >= 90
        1.4 # Highest here to get 90+%ile traces
      else
        # impossible.
        percentile
      end
    end
  end
end
