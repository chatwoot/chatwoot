# frozen_string_literal: true

module Judoscale
  class Metric < Struct.new(:identifier, :value, :time, :queue_name)
    # No queue_name is assumed to be a web request metric
    # Metrics: qt = queue time (default), qd = queue depth, busy
    def initialize(identifier, value, time, queue_name = nil)
      super(identifier, value.to_i, time.utc, queue_name)
    end
  end
end
