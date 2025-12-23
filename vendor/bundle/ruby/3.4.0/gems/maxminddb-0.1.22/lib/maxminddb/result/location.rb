module MaxMindDB
  class Result
    class Location
      def initialize(raw)
        @raw = raw || {}
      end

      def latitude
        raw['latitude']
      end

      def longitude
        raw['longitude']
      end

      def metro_code
        raw['metro_code']
      end

      def time_zone
        raw['time_zone']
      end

      def accuracy_radius
        raw['accuracy_radius']
      end

      private

      attr_reader :raw
    end
  end
end
