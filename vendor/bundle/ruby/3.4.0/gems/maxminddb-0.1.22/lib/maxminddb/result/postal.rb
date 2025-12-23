module MaxMindDB
  class Result
    class Postal
      def initialize(raw)
        @raw = raw || {}
      end

      def code
        raw['code']
      end

      private

      attr_reader :raw
    end
  end
end
