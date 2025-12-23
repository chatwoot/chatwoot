# A lack of app server to integrate with.
# Null Object pattern

module ScoutApm
  module ServerIntegrations
    class Null
      attr_reader :logger

      def initialize(logger)
        @logger = logger
      end

      def name
        :null
      end

      def present?
        true
      end

      def install
        # Nothing to do.
      end

      def forking?
        false
      end

      def found?
        false
      end
    end
  end
end
