module ScoutApm
  module BackgroundJobIntegrations
    class Faktory
      attr_reader :logger

      def name
        :faktory
      end

      def present?
        defined?(::Faktory)
      end

      def forking?
        false
      end

      def install
        add_middleware
        install_processor
      end

      def add_middleware
        ::Faktory.configure_worker do |config|
          config.worker_middleware do |chain|
            chain.add FaktoryMiddleware
          end
        end
      end

      def install_processor
        require 'faktory/processor' # sidekiq v4 has not loaded this file by this point

        ::Faktory::Processor.class_eval do
          def initialize_with_scout(*args)
            agent = ::ScoutApm::Agent.instance
            agent.start
            initialize_without_scout(*args)
          end

          alias_method :initialize_without_scout, :initialize
          alias_method :initialize, :initialize_with_scout
        end
      end
    end

    # We insert this middleware into the Sidekiq stack, to capture each job,
    # and time them.
    class FaktoryMiddleware
      def call(worker_instance, job)
        queue = job["queue"]

        req = ScoutApm::RequestManager.lookup
        req.annotate_request(:queue_latency => latency(job))

        begin
          req.start_layer(ScoutApm::Layer.new('Queue', queue))
          started_queue = true
          req.start_layer(ScoutApm::Layer.new('Job', job_class(job)))
          started_job = true

          yield
        rescue
          req.error!
          raise
        ensure
          req.stop_layer if started_job
          req.stop_layer if started_queue
        end
      end

      UNKNOWN_CLASS_PLACEHOLDER = 'UnknownJob'.freeze
      ACTIVE_JOB_KLASS = 'ActiveJob::QueueAdapters::FaktoryAdapter::JobWrapper'.freeze

      def job_class(job)
        job_class = job.fetch('jobtype', UNKNOWN_CLASS_PLACEHOLDER)

        if job_class == ACTIVE_JOB_KLASS && job.key?('custom') && job['custom'].key?('wrapped')
          begin
            job_class = job['custom']['wrapped']
          rescue
            ACTIVE_JOB_KLASS
          end
        end

        job_class
      rescue
        UNKNOWN_CLASS_PLACEHOLDER
      end

      def latency(job, time = Time.now)
        created_at = Time.parse(job['enqueued_at'] || job['created_at'])
        if created_at
          (time - created_at)
        else
          0
        end
      rescue
        0
      end
    end
  end
end
