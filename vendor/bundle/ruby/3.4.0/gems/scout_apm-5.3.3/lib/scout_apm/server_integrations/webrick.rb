module ScoutApm
  module ServerIntegrations
    class Webrick
      attr_reader :logger

      def initialize(logger)
        @logger = logger
      end

      def name
        :webrick
      end

      def forking?; false; end

      def present?
        defined?(::WEBrick) && defined?(::WEBrick::VERSION)
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


