module ScoutApm
  module BackgroundJobIntegrations
    class Sidekiq
      attr_reader :logger

      def name
        :sidekiq
      end

      def present?
        defined?(::Sidekiq) && File.basename($PROGRAM_NAME).start_with?('sidekiq')
      end

      def forking?
        false
      end

      def install
        install_tracer
        add_middleware
        install_processor
      end

      def install_tracer
        # ScoutApm::Tracer is not available when this class is defined
        SidekiqMiddleware.class_eval do
          include ScoutApm::Tracer
        end
      end

      def add_middleware
        ::Sidekiq.configure_server do |config|
          config.server_middleware do |chain|
            chain.add SidekiqMiddleware
          end
        end
      end

      def install_processor
        ::Sidekiq.configure_server do |config|
          config.on(:startup) do
            agent = ::ScoutApm::Agent.instance
            agent.start
          end
        end
      end
    end

    # We insert this middleware into the Sidekiq stack, to capture each job,
    # and time them.
    class SidekiqMiddleware
      def call(_worker, msg, queue)
        req = ScoutApm::RequestManager.lookup
        req.annotate_request(:queue_latency => latency(msg))

        begin
          req.start_layer(ScoutApm::Layer.new('Queue', queue))
          started_queue = true
          req.start_layer(ScoutApm::Layer.new('Job', job_class(msg)))
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
      ACTIVE_JOB_KLASS = 'ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper'.freeze
      DELAYED_WRAPPER_KLASS = 'Sidekiq::Extensions::DelayedClass'.freeze


      # Capturing the class name is a little tricky, since we need to handle several cases:
      # 1. ActiveJob, with the class in the key 'wrapped'
      # 2. ActiveJob, but the 'wrapped' key is wrong (due to YAJL serializing weirdly), find it in args.job_class
      # 3. DelayedJob wrapper, deserializing using YAML into the real object, which can be introspected
      # 4. No wrapper, just sidekiq's class
      def job_class(msg)
        job_class = msg.fetch('class', UNKNOWN_CLASS_PLACEHOLDER)

        if job_class == ACTIVE_JOB_KLASS && msg.key?('wrapped') && msg['wrapped'].is_a?(String)
          begin
            job_class = msg['wrapped'].to_s
          rescue
            ACTIVE_JOB_KLASS
          end
        elsif job_class == ACTIVE_JOB_KLASS && msg.try(:[], 'args').try(:[], 'job_class')
          begin
            job_class = msg['args']['job_class'].to_s
          rescue
            ACTIVE_JOB_KLASS
          end
        elsif job_class == DELAYED_WRAPPER_KLASS
          begin
            # Extract the info out of the wrapper
            yml = msg['args'].first
            deserialized_args = YAML.load(yml)
            klass, method, *rest = deserialized_args

            # If this is an instance of a class, get the class itself
            # Prevents instances from coming through named like "#<Foo:0x007ffd7a9dd8a0>"
            klass = klass.class unless klass.is_a? Module

            job_class = [klass, method].map(&:to_s).join(".")
          rescue
            DELAYED_WRAPPER_KLASS
          end
        end

        job_class
      rescue
        UNKNOWN_CLASS_PLACEHOLDER
      end

      def latency(msg, time = Time.now.to_f)
        created_at = msg['enqueued_at'] || msg['created_at']
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
