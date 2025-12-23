module ScoutApm
  module ServerIntegrations
    class Rainbows
      attr_reader :logger

      def initialize(logger)
        @logger = logger
      end

      def name
        :rainbows
      end

      def forking?; true; end

      def present?
        if defined?(::Rainbows) && defined?(::Rainbows::HttpServer)
          ObjectSpace.each_object(::Rainbows::HttpServer) { |x| return true }
          false
        end
      end

      def install
        logger.info "Installing Rainbows worker loop."

        Rainbows::HttpServer.class_eval do
          old = instance_method(:worker_loop)
          define_method(:worker_loop) do |worker|
            ScoutApm::Agent.instance.start_background_worker
            old.bind(self).call(worker)
          end
        end
      end

      def found?
        true
      end
    end
  end
end
