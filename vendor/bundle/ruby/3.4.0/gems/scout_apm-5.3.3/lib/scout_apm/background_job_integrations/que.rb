module ScoutApm
  module BackgroundJobIntegrations
    class Que

      UNKNOWN_CLASS_PLACEHOLDER = 'UnknownJob'.freeze
      ACTIVE_JOB_KLASS = 'ActiveJob::QueueAdapters::QueAdapter::JobWrapper'.freeze
      UNKNOWN_QUEUE_PLACEHOLDER = 'UnknownQueue'.freeze

      attr_reader :logger

      def name
        :que
      end

      def present?
        if defined?(::Que) && File.basename($PROGRAM_NAME).start_with?('que')
          # 0.x releases used "Version" constant.
          # 1.x releases used "VERSION" constant.
          return defined?(::Que::Version)
        end
      end

      def forking?
        false
      end

      def install
        install_tracer
        install_worker
        install_job
      end

      def install_tracer
        ::Que::Job.class_eval do
          include ScoutApm::Tracer
        end
      end

      def install_worker
        ::Que::Worker.class_eval do
          def initialize_with_scout(*args)
            agent = ::ScoutApm::Agent.instance
            agent.start
            initialize_without_scout(*args)
          end

          alias_method :initialize_without_scout, :initialize
          alias_method :initialize, :initialize_with_scout
        end
      end

      def install_job
        ::Que::Job.class_eval do
          # attrs = {
          #   "queue"=>"",
          #   "priority"=>100,
          #   "run_at"=>2018-12-19 15:12:32 -0700,
          #   "job_id"=>4,
          #   "job_class"=>"ExampleJob",
          #   "args"=>[{"key"=>"value"}],
          #   "error_count"=>0
          # }
          #
          # With ActiveJob, v0.14.3:
          # attrs = {
          #   "queue"=>"",
          #   "priority"=>100,
          #   "run_at"=>2018-12-19 15:29:18 -0700,
          #   "job_id"=>6,
          #   "job_class"=>"ActiveJob::QueueAdapters::QueAdapter::JobWrapper",
          #   "args"=> [{
          #     "job_class"=>"ExampleJob",
          #     "job_id"=>"60798b45-4b55-436e-806d-693939266c97",
          #     "provider_job_id"=>nil,
          #     "queue_name"=>"default",
          #     "priority"=>nil,
          #     "arguments"=>[],
          #     "executions"=>0,
          #     "locale"=>"en"
          #   }],
          #   "error_count"=>0
          # }
          #
          # With ActiveJob, v1.0:
          #   There are changes here to make Que more compatible with ActiveJob
          #   and this probably needs to be revisited.

          def _run_with_scout(*args)
            # default queue unless specifed is a blank string
            queue = attrs['queue'] || UNKNOWN_QUEUE_PLACEHOLDER

            job_class = begin
                          if self.class == ActiveJob::QueueAdapters::QueAdapter::JobWrapper
                            Array(attrs['args']).first['job_class'] || UNKNOWN_CLASS_PLACEHOLDER
                          else
                            self.class.name
                          end
                        rescue => e
                          UNKNOWN_CLASS_PLACEHOLDER
                        end

            latency = begin
                        Time.now - attrs['run_at']
                      rescue
                        0
                      end

            req = ScoutApm::RequestManager.lookup
            req.annotate_request(:queue_latency => latency)

            begin
              req.start_layer(ScoutApm::Layer.new('Queue', queue))
              started_queue = true
              req.start_layer(ScoutApm::Layer.new('Job', job_class))
              started_job = true

              _run_without_scout(*args)
            rescue Exception => e
              req.error!
              raise
            ensure
              req.stop_layer if started_job
              req.stop_layer if started_queue
            end
          end

          alias_method :_run_without_scout, :_run
          alias_method :_run, :_run_with_scout
        end
      end
    end

  end
end
