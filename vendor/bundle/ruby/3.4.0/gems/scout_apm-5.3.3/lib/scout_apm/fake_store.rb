# A stand-in for Store. This one does not accumulate data, it just throws it away.
# Methods in here are the minimal set needed to fool calling objects
module ScoutApm
  class FakeStore

    def initialize
    end

    def current_timestamp
      # why a time passed in here? So the histogram in tracked_request.record! doesn't accumulate data indefinitely.
      StoreReportingPeriodTimestamp.new(Time.parse('2000-01-01 00:00:00'))
    end

    def track!(metrics, options={})
    end

    def track_one!(type, name, value, options={})
    end

    def track_trace!(trace, type)
    end

    def track_histograms!(histograms, options={})
    end

    def track_db_query_metrics!(db_query_metric_set, options={})
    end

    def track_external_service_metrics!(external_service_metric_set, options={})
    end

    def track_slow_transaction!(slow_transaction)
    end

    def track_job!(job)
    end

    def track_slow_job!(job)
    end

    def write_to_layaway(layaway, force=false)
    end

    def add_sampler(sampler)
    end

    def tick!
    end
  end
end
