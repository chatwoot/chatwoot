# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/coerce'

module NewRelic
  class MetricData
    # a NewRelic::MetricSpec object
    attr_reader :metric_spec
    # a NewRelic::Agent::Stats object
    attr_accessor :stats

    include NewRelic::Coerce

    def initialize(metric_spec, stats)
      @original_spec = nil
      @metric_spec = metric_spec
      self.stats = stats
    end

    def eql?(o)
      (metric_spec.eql?(o.metric_spec)) && (stats.eql?(o.stats))
    end

    def hash
      [metric_spec, stats].hash
    end

    def inspect
      "#<MetricData metric_spec:#{metric_spec.inspect}, stats:#{stats.inspect}>"
    end

    # assigns a new metric spec, and retains the old metric spec as
    # @original_spec if it exists currently
    def metric_spec=(new_spec)
      @original_spec = @metric_spec if @metric_spec
      @metric_spec = new_spec
    end

    def original_spec
      @original_spec || @metric_spec
    end

    def to_collector_array(encoder = nil)
      stat_key = {'name' => metric_spec.name, 'scope' => metric_spec.scope}
      [stat_key, stats_collector_array(stat_key)]
    end

    def to_json(*a)
      %Q({"metric_spec":#{metric_spec.to_json},"stats":{"total_exclusive_time":#{stats.total_exclusive_time},"min_call_time":#{stats.min_call_time},"call_count":#{stats.call_count},"sum_of_squares":#{stats.sum_of_squares},"total_call_time":#{stats.total_call_time},"max_call_time":#{stats.max_call_time}}})
    end

    def to_s
      "#{metric_spec.name}(#{metric_spec.scope}): #{stats}"
    end

    private

    def stats_collector_array(stat_key)
      [[:call_count, Integer], [:total_call_time, Float],
        [:total_exclusive_time, Float], [:min_call_time, Float],
        [:max_call_time, Float], [:sum_of_squares, Float]].map do |attr_types|
        if attr_types[1].eql?(Integer)
          int(stats.send(attr_types[0]), stat_key)
        elsif attr_types[1].eql?(Float)
          float(stats.send(attr_types[0]), stat_key)
        end
      end
    end
  end
end
