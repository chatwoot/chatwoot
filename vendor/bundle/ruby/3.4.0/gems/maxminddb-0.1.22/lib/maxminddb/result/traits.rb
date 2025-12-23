module MaxMindDB
  class Result
    class Traits
      def initialize(raw)
        @raw = raw || {}
      end

      def is_anonymous_proxy
        raw['is_anonymous_proxy']
      end

      def is_satellite_provider
        raw['is_satellite_provider']
      end

      private

      attr_reader :raw
    end
  end
end
