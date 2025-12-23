# Stats that are associated with each instrumented method.
module ScoutApm
class MetricStats
  attr_accessor :call_count
  attr_accessor :min_call_time
  attr_accessor :max_call_time
  attr_accessor :total_call_time
  attr_accessor :total_exclusive_time
  attr_accessor :sum_of_squares
  attr_accessor :queue
  attr_accessor :latency

  def initialize(scoped = false)
    @scoped = scoped
    self.call_count = 0
    self.total_call_time = 0.0
    self.total_exclusive_time = 0.0
    self.min_call_time = 0.0
    self.max_call_time = 0.0
    self.sum_of_squares = 0.0
  end

  # Note, that you must include exclusive_time if you wish to set
  # extra_metrics. A two argument use of this method won't do that.
  def update!(call_time, exclusive_time=call_time, extra_metrics={})
    # If this metric is scoped inside another, use exclusive time for min/max and sum_of_squares. Non-scoped metrics
    # (like controller actions) track the total call time.
    t = (@scoped ? exclusive_time : call_time)
    self.min_call_time = t if self.call_count == 0 or t < min_call_time
    self.max_call_time = t if self.call_count == 0 or t > max_call_time
    self.call_count += 1
    self.total_call_time += call_time
    self.total_exclusive_time += exclusive_time
    self.sum_of_squares += (t * t)
    if extra_metrics
      self.queue = extra_metrics[:queue] if extra_metrics[:queue]
      self.latency = extra_metrics[:latency] if extra_metrics[:latency]
    end
    self
  end

  # combines data from another MetricStats object
  def combine!(other)
    self.call_count += other.call_count
    self.total_call_time += other.total_call_time
    self.total_exclusive_time += other.total_exclusive_time
    self.min_call_time = other.min_call_time if self.min_call_time.zero? or other.min_call_time < self.min_call_time
    self.max_call_time = other.max_call_time if other.max_call_time > self.max_call_time
    self.sum_of_squares += other.sum_of_squares
    self
  end

  def as_json
    json_attributes = [
      :call_count,
      :max_call_time,
      :min_call_time,
      :total_call_time,
      :total_exclusive_time,
    ]
    ScoutApm::AttributeArranger.call(self, json_attributes)
  end
end
end
