module ScoutApm
  module ServerIntegrations
    class Thin
      attr_reader :logger

      def initialize(logger)
        @logger = logger
      end

      def name
        :thin
      end

      def forking?; false; end

      def present?
        found_thin = false

        # This code block detects when thin is run as:
        # `thin start`
        if defined?(::Thin) && defined?(::Thin::Server)
          # Ensure Thin is actually initialized. It could just be required and not running.
          ObjectSpace.each_object(::Thin::Server) { |x| found_thin = true }
        end

        # This code block detects when thin is run as:
        # `rails server`
        if defined?(::Rails::Server)
          ObjectSpace.each_object(::Rails::Server) { |x| found_thin ||= (x.instance_variable_get(:@_server).to_s == "Rack::Handler::Thin") }
        end

        found_thin
      end

      # TODO: What does it mean to install on a non-forking env?
      def install
      end

      def found?
        true
      end
    end
  end
end

