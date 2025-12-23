module ScoutApm
  class StackItem
    attr_accessor :children_time
    attr_reader :metric_name, :start_time

    def initialize(metric_name)
      @metric_name = metric_name
      @start_time = Time.now
      @children_time = 0
    end

    def ==(o)
      self.eql?(o)
    end

    def eql?(o)
      self.class == o.class && metric_name.eql?(o.metric_name)
    end
  end # class StackItem
end
