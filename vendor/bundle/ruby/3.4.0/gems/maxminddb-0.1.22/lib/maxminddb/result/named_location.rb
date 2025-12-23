module MaxMindDB
  class Result
    class NamedLocation
      def initialize(raw)
        @raw = raw || {}
      end

      def code
        raw['code']
      end

      def geoname_id
        raw['geoname_id']
      end

      def is_in_european_union
        raw['is_in_european_union']
      end

      def iso_code
        raw['iso_code']
      end

      def name(locale = :en)
        raw['names'] && raw['names'][locale.to_s]
      end

      private

      attr_reader :raw
    end
  end
end
