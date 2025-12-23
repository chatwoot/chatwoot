
module ScoutApm
  module Serializers
    class HistogramsSerializerToJson
      attr_reader :histograms

      def initialize(histograms)
        @histograms = histograms
      end

      def as_json
        histograms.map do |histo|
          {
            "name" => histo.name,
            "histogram" => histo.histogram.as_json,
          }
        end
      end
    end
  end
end
