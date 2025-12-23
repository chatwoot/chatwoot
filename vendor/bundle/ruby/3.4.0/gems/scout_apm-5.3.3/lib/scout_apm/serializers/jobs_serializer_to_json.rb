module ScoutApm
  module Serializers
    class JobsSerializerToJson
      attr_reader :jobs

      # Jobs is a pre-deduped/combined set of job records.
      def initialize(jobs)
        @jobs = jobs
      end

      # An array of job records
      def as_json
        jobs.map do |job|
          {
            "queue" => job.queue_name,
            "name" => job.job_name,
            "count" => job.run_count,
            "errors" => job.errors,
            "total_time" => job.total_time.as_json,
            "exclusive_time" => job.exclusive_time.as_json,
            "metrics" => MetricsToJsonSerializer.new(job.metrics).as_json, # New style of metrics
          }
        end
      end
    end
  end
end

