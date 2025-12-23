module ScoutApm
  module BackgroundJobIntegrations
    class Shoryuken
      attr_reader :logger

      def name
        :shoryuken
      end

      def present?
        defined?(::Shoryuken) && File.basename($PROGRAM_NAME).start_with?('shoryuken')
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
        ShoryukenMiddleware.class_eval do
          include ScoutApm::Tracer
        end
      end

      def add_middleware
        ::Shoryuken.configure_server do |config|
          config.server_middleware do |chain|
            chain.add ShoryukenMiddleware
          end
        end
      end

      def install_processor
        # celluloid has not loaded by this point and older versions of `shorykuen/processor` assume that it did
        require 'celluloid' if defined?(::Shoryuken::VERSION) && ::Shoryuken::VERSION < '3'
        require 'shoryuken/processor' # sidekiq v4 has not loaded this file by this point

        ::Shoryuken::Processor.class_eval do
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

    # We insert this middleware into the Shoryuken stack, to capture each job,
    # and time them.
    class ShoryukenMiddleware
      def call(worker_instance, queue, msg, body)
        job_class =
          begin
            if worker_instance.class.to_s == ACTIVE_JOB_KLASS
              body["job_class"]
            else
              worker_instance.class.to_s
            end
          rescue
            UNKNOWN_CLASS_PLACEHOLDER
          end

        req = ScoutApm::RequestManager.lookup
        req.annotate_request(:queue_latency => latency(msg))

        begin
          req.start_layer(ScoutApm::Layer.new('Queue', queue))
          started_queue = true
          req.start_layer(ScoutApm::Layer.new('Job', job_class))
          started_job = true

          yield
        rescue Exception => e
          req.error!
          raise
        ensure
          req.stop_layer if started_job
          req.stop_layer if started_queue
        end
      end

      UNKNOWN_CLASS_PLACEHOLDER = 'UnknownJob'.freeze
      ACTIVE_JOB_KLASS = 'ActiveJob::QueueAdapters::ShoryukenAdapter::JobWrapper'.freeze

      def latency(msg, time = Time.now.to_f)
        ms_since_epoch_str = msg.attributes.fetch('SentTimestamp', 0)
        return 0 if ms_since_epoch_str.nil?

        # Convert from ms to seconds as a float
        created_at = ms_since_epoch_str.to_i / 1000.0

        time - created_at
      rescue => e
        0
      end
    end
  end
end

# MSG: #<Shoryuken::Message:0x007fb742a96950 @client=#<Aws::SQS::Client>
# @data=#<struct Aws::SQS::Types::Message message_id="7a2ef0af-2bbd-4368-9c39-34cc89e4da15"
# receipt_handle="AQEB8YK4+TCyvCM3p0EanmhZiTbBCM6uMeyCn7zibNn+XZcMnjZp2Z8D8yoUs4mMX9vJqlQvaS8gRUGBYG7ciq+BthmEqDWfxbcJ8jN+Vp/PXIyyTgYL3vvlnHcQajDz3H7Bd30UmLu80sqeLSjXXNEiKolcIxdGuIsIdSM4aUEPXsecr5eH7o8pZHcDV+bGcLuE7VbvKRZT3A2HeezW7wWwkYve/wt6asS1bYB+VJurAORY0y26xgCooEMNbs5yqxcnSD/CiNT822hkmw0eHNpTHOjF9WLgxLbkpITnQl1lsfK5TsM/ukE1oB1F9nN5ZkCBVCDeFYJDBAo81VvVV9G16knxyCYzjnmpwhvHg2BqTA56iV6r9KZYbiwOaMPdH5ealKLRnWhFoLOEPNA4yjG1yw=="
# md5_of_body="8b3be018857a74f9e46b4c6ef3c3f515"
# body="Unique Person #7532"
# attributes={"SenderId"=>"AIDAJZXBVF26MLZPE6FOO"
# "ApproximateFirstReceiveTimestamp"=>"1534873932213"
# "ApproximateReceiveCount"=>"1"
# "SentTimestamp"=>"1534873927868"}
# md5_of_message_attributes="c70f52a6566cf42ec5e61e81877132dd"
# message_attributes={"shoryuken_class"=>#<struct Aws::SQS::Types::MessageAttributeValue string_value="DummyWorker"
    # binary_value=nil
    # string_list_values=[]
    # binary_list_values=[]
    # data_type="String">}>
# @queue_url="https://sqs.us-west-2.amazonaws.com/023109228371/shoryuken_test"
# @queue_name="shoryuken_test">

