# Stores one or more minute's worth of Metrics/SlowTransactions in local ram.
# When informed to by the background worker, it pushes the in-ram metrics off to
# the layaway file for cross-process aggregation.
module ScoutApm
  class Store
    def initialize(context)
      @context = context
      @mutex = Monitor.new
      @reporting_periods = Hash.new { |h,k|
        @mutex.synchronize { h[k] = StoreReportingPeriod.new(k, @context) }
      }
      @samplers = []
    end

    def current_timestamp
      StoreReportingPeriodTimestamp.new(Time.now)
    end

    def current_period
      @reporting_periods[current_timestamp]
    end
    private :current_period

    def find_period(timestamp = nil)
      if timestamp
        @reporting_periods[timestamp]
      else
        current_period
      end
    end
    private :find_period

    # Save newly collected metrics
    def track!(metrics, options={})
      @mutex.synchronize {
        period = find_period(options[:timestamp])
        period.absorb_metrics!(metrics)
      }
    end

    def track_histograms!(histograms, options={})
      @mutex.synchronize {
        period = find_period(options[:timestamp])
        period.merge_histograms!(histograms)
      }
    end

    def track_db_query_metrics!(db_query_metric_set, options={})
      @mutex.synchronize {
        period = find_period(options[:timestamp])
        period.merge_db_query_metrics!(db_query_metric_set)
      }
    end

    def track_external_service_metrics!(external_service_metric_set, options={})
      @mutex.synchronize {
        period = find_period(options[:timestamp])
        period.merge_external_service_metrics!(external_service_metric_set)
      }
    end

    def track_one!(type, name, value, options={})
      meta = MetricMeta.new("#{type}/#{name}")
      stat = MetricStats.new(false)
      stat.update!(value)
      track!({meta => stat}, options)
    end

    # Save a new slow transaction
    def track_slow_transaction!(slow_transaction)
      return unless slow_transaction
      @mutex.synchronize {
        current_period.merge_slow_transactions!(slow_transaction)
      }
    end

    def track_job!(job)
      return if job.nil?
      @mutex.synchronize {
        current_period.merge_jobs!(Array(job))
      }
    end

    def track_slow_job!(job)
      return if job.nil?
      @mutex.synchronize {
        current_period.merge_slow_jobs!(Array(job))
      }
    end

    # Take each completed reporting_period, and write it to the layaway passed
    #
    # force - a boolean argument that forces this function to write
    # current-minute metrics.  Useful when we are shutting down the agent
    # during a restart.
    def write_to_layaway(layaway, force=false)
      logger.debug("Writing to layaway#{" (Forced)" if force}")

      to_report = @mutex.synchronize {
        @reporting_periods.select { |time, rp|
          force || (time.timestamp < current_timestamp.timestamp)
        }
      }

      to_report.each { |time, rp| write_reporting_period(layaway, time, rp) }
    end

    # For each tick (minute), be sure we have a reporting period, and that samplers are run for it.
    def tick!
      rp = current_period
      collect_samplers(rp)
    end

    def write_reporting_period(layaway, time, rp)
        layaway.write_reporting_period(rp)
    rescue => e
      logger.warn("Failed writing data to layaway file: #{e.message} / #{e.backtrace}")
    ensure
      logger.debug("Before delete, reporting periods length: #{@reporting_periods.size}")
      deleted_items = @mutex.synchronize { @reporting_periods.delete(time) }
      logger.debug("After delete, reporting periods length: #{@reporting_periods.size}. Did delete #{deleted_items}")
    end
    private :write_reporting_period

    ######################################
    # Sampler support
    def add_sampler(sampler_klass)
      @samplers << sampler_klass.new(@context)
    end

    def collect_samplers(rp)
      @samplers.each do |sampler|
        begin
          sampler.metrics(rp.timestamp, self)
        rescue => e
          logger.info "Error reading #{sampler.human_name} for period: #{rp}"
          logger.debug "#{e.message}\n\t#{e.backtrace.join("\n\t")}"
        end
      end
    end
    private :collect_samplers

    def logger
      @context.logger
    end
    private :logger
  end

  # A timestamp, normalized to the beginning of a minute. Used as a hash key to
  # bucket metrics into per-minute groups
  class StoreReportingPeriodTimestamp
    attr_reader :timestamp

    def initialize(time=Time.now)
      @raw_time = time.utc # The actual time passed in. Store it so we can to_s it without reparsing a timestamp
      @timestamp = @raw_time.to_i - @raw_time.sec # The normalized time (integer) to compare by
    end

    def self.minutes_ago(min, base_time=Time.now)
      adjusted = base_time - (min * 60)
      new(adjusted)
    end

    def to_s
      strftime
    end

    def strftime(pattern=nil)
      if pattern.nil?
        to_time.iso8601
      else
        to_time.strftime(pattern)
      end
    end

    def to_time
      Time.at(@timestamp)
    end

    def eql?(o)
      self.class == o.class && timestamp.eql?(o.timestamp)
    end

    def ==(o)
      self.eql?(o)
    end

    def hash
      timestamp.hash
    end

    def age_in_seconds
      Time.now.to_i - timestamp
    end
  end

  # One period of Storage. Typically 1 minute
  class StoreReportingPeriod
    # A ScoredItemSet holding the "best" traces for the period
    attr_reader :request_traces

    # A ScoredItemSet holding the "best" traces for the period
    attr_reader :job_traces

    # An Array of HistogramsReport
    attr_reader :histograms

    # A StoreReportingPeriodTimestamp representing the time that this
    # collection of metrics is for
    attr_reader :timestamp

    attr_reader :metric_set

    attr_reader :db_query_metric_set

    attr_reader :external_service_metric_set

    def initialize(timestamp, context)
      @timestamp = timestamp
      @context = context

      @request_traces = ScoredItemSet.new(context.config.value('max_traces'))
      @job_traces = ScoredItemSet.new(context.config.value('max_traces'))

      @histograms = []

      @metric_set = MetricSet.new
      @db_query_metric_set = DbQueryMetricSet.new(context)
      @external_service_metric_set = ExternalServiceMetricSet.new(context)

      @jobs = Hash.new
    end

    def logger
      @context.logger
    end
    private :logger

    # Merges another StoreReportingPeriod into this one
    def merge(other)
      self.
        merge_metrics!(other.metric_set).
        merge_slow_transactions!(other.slow_transactions_payload).
        merge_jobs!(other.jobs).
        merge_slow_jobs!(other.slow_jobs_payload).
        merge_histograms!(other.histograms).
        merge_db_query_metrics!(other.db_query_metric_set).
        merge_external_service_metrics!(other.external_service_metric_set)
      self
    end

    #################################
    # Add metrics as they are recorded
    #################################

    # For absorbing an array of metric {Meta => Stat} records
    def absorb_metrics!(metrics)
      metric_set.absorb_all(metrics)
      self
    end

    # For merging when you have another metric_set object
    # Makes sure that you don't duplicate error count records
    def merge_metrics!(other_metric_set)
      metric_set.combine!(other_metric_set)
      self
    end

    def merge_db_query_metrics!(other_metric_set)
      db_query_metric_set.combine!(other_metric_set)
      self
    end

    def merge_external_service_metrics!(other_metric_set)
      if other_metric_set.nil?
        logger.debug("Missing other_metric_set for merge_external_service_metrics - skipping.")
      else
        external_service_metric_set.combine!(other_metric_set)
      end
      self
    end

    def merge_slow_transactions!(new_transactions)
      Array(new_transactions).each do |one_transaction|
        request_traces << one_transaction
      end

      self
    end

    def merge_jobs!(jobs)
      Array(jobs).each do |job|
        if @jobs.has_key?(job)
          @jobs[job].combine!(job)
        else
          @jobs[job] = job
        end
      end

      self
    end

    def merge_slow_jobs!(new_jobs)
      Array(new_jobs).each do |job|
        job_traces << job
      end

      self
    end

    def merge_histograms!(new_histograms)
      new_histograms = Array(new_histograms)
      @histograms = (histograms + new_histograms).
        group_by { |histo| histo.name }.
        map { |(_, histos)|
          histos.inject { |merged, histo| merged.combine!(histo) }
        }

      self
    end

    #################################
    # Retrieve Metrics for reporting
    #################################
    def metrics_payload
      metric_set.metrics
    end

    def slow_transactions_payload
      request_traces.to_a
    end

    def jobs
      @jobs.values
    end

    def slow_jobs_payload
      job_traces.to_a
    end

    def db_query_metrics_payload
      db_query_metric_set.metrics_to_report
    end

    def external_service_metrics_payload
      external_service_metric_set.metrics_to_report
    end

    #################################
    # Debug Helpers
    #################################

    def request_count
      metrics_payload.
        select { |meta,stats| meta.metric_name =~ /\AController/ }.
        inject(0) {|sum, (_, stat)| sum + stat.call_count }
    end
  end
end

