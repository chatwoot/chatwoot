# This is different than other BackgroundJobIntegrations and must be prepended
# manually in each job.
#
# class MyWorker
#   prepend ScoutApm::BackgroundJobIntegrations::LegacySneakers
#
#   def work(msg)
#     ...
#   end
# end
module ScoutApm
  module BackgroundJobIntegrations
    module LegacySneakers
      UNKNOWN_QUEUE_PLACEHOLDER = 'default'.freeze

      def self.prepended(base)
        ScoutApm::Agent.instance.logger.info("Prepended LegacySneakers in #{base}")
      end

      def initialize(*args)
        super

        # Save off the existing value to call the correct existing work
        # function in the instrumentation. But then override Sneakers to always
        # use the extra-argument version, which has data Scout needs
        @call_work = respond_to?(:work)
      end

      def work_with_params(msg, delivery_info, metadata)
        queue = delivery_info[:routing_key] || UNKNOWN_QUEUE_PLACEHOLDER
        job_class = self.class.name
        req = ScoutApm::RequestManager.lookup

        begin
          req.start_layer(ScoutApm::Layer.new('Queue', queue))
          started_queue = true
          req.start_layer(ScoutApm::Layer.new('Job', job_class))
          started_job = true

          if @call_work
            work(msg)
          else
            super
          end
        rescue Exception
          req.error!
          raise
        ensure
          req.stop_layer if started_job
          req.stop_layer if started_queue
        end
      end
    end
  end
end
