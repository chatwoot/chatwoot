module ScoutApm
  module BackgroundJobIntegrations
    class DelayedJob
      ACTIVE_JOB_KLASS = 'ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper'.freeze
      DJ_PERFORMABLE_METHOD = 'Delayed::PerformableMethod'.freeze

      attr_reader :logger

      def name
        :delayed_job
      end

      def present?
        defined?(::Delayed::Worker)
      end

      def forking?
        false
      end

      def install
        plugin = Class.new(Delayed::Plugin) do
          require 'delayed_job'

          callbacks do |lifecycle|
            lifecycle.around(:invoke_job) do |job, *args, &block|
              ScoutApm::Agent.instance.start_background_worker unless ScoutApm::Agent.instance.background_worker_running?

              name = begin
                       case job.payload_object.class.to_s

                       # ActiveJob's class wraps the actual job class
                       when ACTIVE_JOB_KLASS
                         job.payload_object.job_data["job_class"]

                       # An adhoc job, called like `@user.delay.fib(10)`.
                       # returns a string like "User#fib"
                       when DJ_PERFORMABLE_METHOD
                         job.name

                       # A "real" job called like `Delayed::Job.enqueue(MyJob.new)`
                       # returns "MyJob"
                       else
                         job.payload_object.class.to_s
                       end
                     rescue
                       # Fall back to whatever DJ thinks the name is.
                       job.name
                     end

              queue = job.queue || "default"

              req = ScoutApm::RequestManager.lookup

              begin
                latency = Time.now - [job.created_at, job.run_at].max
                req.annotate_request(:queue_latency => latency)
              rescue
              end

              queue_layer = ScoutApm::Layer.new('Queue', queue)
              job_layer = ScoutApm::Layer.new('Job', name)

              begin
                req.start_layer(queue_layer)
                started_queue = true
                req.start_layer(job_layer)
                started_job = true

                # Call the job itself.
                block.call(job, *args)
              rescue
                req.error!
                raise
              ensure
                req.stop_layer if started_job
                req.stop_layer if started_queue
              end
            end
          end
        end

        Delayed::Worker.plugins << plugin # ScoutApm::BackgroundJobIntegrations::DelayedJobPlugin
      end
    end
  end
end

