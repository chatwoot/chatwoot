# Records details about all runs of a given job.
#
# Contains:
#   Queue Name
#   Job Name
#   Job Runtime - histogram
#   Metrics collected during the run (Database, HTTP, View, etc)
module ScoutApm
  class JobRecord
    attr_reader :queue_name
    attr_reader :job_name
    attr_reader :total_time
    attr_reader :exclusive_time
    attr_reader :errors
    attr_reader :metric_set

    def initialize(queue_name, job_name, total_time, exclusive_time, errors, metrics)
      @queue_name = queue_name
      @job_name = job_name

      @total_time = NumericHistogram.new(50)
      @total_time.add(total_time)

      @exclusive_time = NumericHistogram.new(50)
      @exclusive_time.add(exclusive_time)

      @errors = errors.to_i

      @metric_set = MetricSet.new
      @metric_set.absorb_all(metrics)
    end

    # Modifies self and returns self, after merging in `other`.
    def combine!(other)
      if !self.eql?(other)
        ScoutApm::Agent.instance.logger.debug("Mismatched Merge of Background Job: (Queue #{queue_name} == #{other.queue_name}) (Name #{job_name} == #{other.job_name}) (Hash #{hash} == #{other.hash})")
        return self
      end

      @errors += other.errors
      @metric_set = metric_set.combine!(other.metric_set)
      @total_time.combine!(other.total_time)
      @exclusive_time.combine!(other.exclusive_time)

      self
    end

    def run_count
      total_time.total
    end

    def metrics
      metric_set.metrics
    end


    ######################
    # Hash Key interface
    ######################

    def ==(o)
      self.eql?(o)
    end

    def hash
      h = queue_name.downcase.hash
      h ^= job_name.downcase.hash
      h
    end

    def eql?(o)
     self.class == o.class &&
       queue_name.downcase == o.queue_name.downcase &&
       job_name.downcase == o.job_name.downcase
    end
  end
end

