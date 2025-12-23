module ScoutApm
  module ServerIntegrations
    class Unicorn
      attr_reader :logger

      def initialize(logger)
        @logger = logger
      end

      def name
        :unicorn
      end

      def forking?
        return true unless (defined?(::Unicorn) && defined?(::Unicorn::Configurator))
        ObjectSpace.each_object(::Unicorn::Configurator).first[:preload_app]
      rescue
        true
      end

      def present?
        if defined?(::Unicorn)
          logger.debug "[UNICORN] - ::Unicorn is defined"
        else
          logger.debug "[UNICORN] - ::Unicorn was not found"
          return false
        end

        if defined?(::Unicorn::HttpServer)
          logger.debug "[UNICORN] - ::Unicorn::HttpServer is defined"
        else
          logger.debug "[UNICORN] - ::Unicorn::HttpServer was not found"
          return false
        end

        # Ensure Unicorn is actually initialized. It could just be required and not running.
        ObjectSpace.each_object(::Unicorn::HttpServer) do |x|
          logger.debug "[UNICORN] - Running ::Unicorn::HttpServer found."
          return true
        end

        logger.debug "[UNICORN] - Running ::Unicorn::HttpServer was not found."
        false
      end

      def install
        logger.info "Installing Unicorn worker loop."
        ::Unicorn::HttpServer.class_eval do
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

