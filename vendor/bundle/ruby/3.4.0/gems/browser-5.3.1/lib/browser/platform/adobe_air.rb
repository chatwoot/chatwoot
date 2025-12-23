# frozen_string_literal: true

module Browser
  class Platform
    class AdobeAir < Base
      def match?
        ua.include?("AdobeAIR")
      end

      def version
        ua[%r{AdobeAIR/([\d.]+)}, 1]
      end

      def name
        "Adobe AIR"
      end

      def id
        :adobe_air
      end
    end
  end
end
