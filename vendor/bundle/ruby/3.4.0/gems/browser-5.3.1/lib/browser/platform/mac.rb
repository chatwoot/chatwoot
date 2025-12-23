# frozen_string_literal: true

module Browser
  class Platform
    class Mac < Base
      def version
        (ua[/Mac OS X\s*([0-9_.]+)?/, 1] || "0").tr("_", ".")
      end

      def name
        return "macOS" if platform.mac?(">= 10.12")

        "Mac OS X"
      end

      def id
        :mac
      end

      def match?
        ua.include?("Mac")
      end
    end
  end
end
