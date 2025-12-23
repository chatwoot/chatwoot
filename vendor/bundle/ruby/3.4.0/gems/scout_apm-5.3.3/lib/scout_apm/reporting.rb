# Methods related to sending metrics to scoutapp.com.
module ScoutApm
  class Reporting
    attr_reader :context

    def initialize(context)
      @context = context
    end

    def logger
      context.logger
    end

    def reporter
      @reporter ||= ScoutApm::Reporter.new(context, :checkin)
    end

    # The data moves through a treadmill of reporting, coordinating several Rails processes by using an external file.
    # * During the minute it is being recorded by the instruments, it gets
    #   recorded into the ram of each process (in the Store class).
    # * The minute after, each process writes its own metrics to a shared LayawayFile
    # * The minute after that, the first process to wake up pushes the combined
    #   data to the server, and wipes it. Next processes don't have anything to do.
    #
    # At any given point, there is data in each of those steps, moving its way through the process
    def process_metrics
      # Do any per-minute work necessary for the store
      context.store.tick!

      # Write the previous minute's data to the shared-across-process layaway file.
      context.store.write_to_layaway(context.layaway)

      # Attempt to send 2 minutes ago's data up to the server.  This
      # only acctually occurs if this process is the first to wake up this
      # minute.
      report_to_server
    end

    # In a running app, one process will get the period ready for delivery, the others will see 0.
    def report_to_server
      period_to_report = ScoutApm::StoreReportingPeriodTimestamp.minutes_ago(2)

      logger.debug("Attempting to claim #{period_to_report.to_s}")

      did_write = context.layaway.with_claim(period_to_report) do |rps|
        logger.debug("Succeeded claiming #{period_to_report.to_s}")

        begin
          merged = rps.inject { |memo, rp| memo.merge(rp) }
          logger.debug("Merged #{rps.length} reporting periods, delivering")
          metadata = metadata(merged)
          deliver_period(merged,metadata)
          context.extensions.run_periodic_callbacks(merged, metadata)
          true
        rescue => e
          logger.debug("Error merging reporting periods #{e.message}")
          logger.debug("Error merging reporting periods #{e.backtrace}")
          false
        end

      end

      if !did_write
        logger.debug("Failed to obtain claim for #{period_to_report.to_s}")
      end
    end

    def metadata(reporting_period)
      {
        :app_root      => context.environment.root.to_s,
        :unique_id     => ScoutApm::Utils::UniqueId.simple,
        :agent_version => ScoutApm::VERSION,
        :agent_time    => reporting_period.timestamp.to_s,
        :agent_pid     => Process.pid,
        :platform      => "ruby",
      }
    end

    def deliver_period(reporting_period,metadata)
      metrics = reporting_period.metrics_payload
      slow_transactions = reporting_period.slow_transactions_payload
      jobs = reporting_period.jobs
      slow_jobs = reporting_period.slow_jobs_payload
      histograms = reporting_period.histograms
      db_query_metrics = reporting_period.db_query_metrics_payload
      external_service_metrics = reporting_period.external_service_metrics_payload
      traces = (slow_transactions.map(&:span_trace) + slow_jobs.map(&:span_trace)).compact

      log_deliver(metrics, slow_transactions, metadata, slow_jobs, histograms)

      payload = ScoutApm::Serializers::PayloadSerializer.serialize(metadata, metrics, slow_transactions, jobs, slow_jobs, histograms, db_query_metrics, external_service_metrics, traces)
      logger.debug("Sending payload w/ Headers: #{headers.inspect}")

      reporter.report(payload, headers)
    rescue => e
      logger.warn "Error on checkin"
      logger.info e.message
      logger.debug e.backtrace
    end

    def log_deliver(metrics, slow_transactions, metadata, jobs_traces, histograms)
      total_request_count = metrics.
        select { |meta,stats| meta.metric_name =~ /\AController/ }.
        inject(0) {|sum, (_, stat)| sum + stat.call_count }

      memory = metrics.
        find {|meta,stats| meta.metric_name =~ /\AMemory/ }
      process_log_str = if memory
                          "Recorded from #{memory.last.call_count} processes"
                        else
                          "Recorded across (unknown) processes"
                        end

      time_clause       = "[#{Time.parse(metadata[:agent_time]).strftime("%H:%M")}]"
      metrics_clause    = "#{metrics.length} Metrics for #{total_request_count} requests"
      slow_trans_clause = "#{slow_transactions.length} Slow Transaction Traces"
      job_clause        = "#{jobs_traces.length} Job Traces"
      histogram_clause  = "#{histograms.length} Histograms"

      logger.info "#{time_clause} Delivering #{metrics_clause} and #{slow_trans_clause} and #{job_clause}, #{process_log_str}."
      logger.debug("\n\nMetrics: #{metrics.pretty_inspect}\nSlowTrans: #{slow_transactions.pretty_inspect}\nMetadata: #{metadata.inspect.pretty_inspect}\n\n")
    end

    # TODO: Move this into PayloadSerializer?
    # XXX: Remove non-json report format entirely
    def headers
      if ScoutApm::Agent.instance.context.config.value("report_format") == 'json'
        headers = {'Content-Type' => 'application/json'}
      else
        headers = {}
      end
    end

    # Before reporting, lookup metric_id for each MetricMeta. This speeds up
    # reporting on the server-side.
    def add_metric_ids(metrics)
      metrics.each do |meta,stats|
        if metric_id = metric_lookup[meta]
          meta.metric_id = metric_id
        end
      end
    end
  end
end
