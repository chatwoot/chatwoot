module NewrelicSidekiqMetrics
  class Recorder
    attr_reader :metrics

    def initialize
      @metrics = NewrelicSidekiqMetrics.used_metrics
    end

    def call
      metrics.each { |m| record_metric(m) }
    end

    private

    def stats
      @stats ||= Sidekiq::Stats.new
    end

    def get_stat(name)
      return 0 if NewrelicSidekiqMetrics.inline_sidekiq?

      stats.public_send(name)
    end

    def record_metric(name)
      NewRelic::Agent.record_metric(metric_full_name(name), get_stat(name))
    end

    def metric_full_name(name)
      File.join(METRIC_PREFIX, METRIC_MAP.fetch(name))
    end
  end
end
