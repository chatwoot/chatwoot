# frozen_string_literal: true

module Browser
  class Platform
    class Unknown < Base
      def version
        "0"
      end

      def name
        "Unknown"
      end

      def id
        :unknown_platform
      end

      def match?
        true
      end
    end
  end
end
