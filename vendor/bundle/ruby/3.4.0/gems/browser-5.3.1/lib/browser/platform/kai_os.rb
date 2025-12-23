# frozen_string_literal: true

module Browser
  class Platform
    class KaiOS < Base
      def version
        ua[%r{KAIOS/([\d.]+)}, 1]
      end

      def name
        "KaiOS"
      end

      def id
        :kai_os
      end

      def match?
        ua.include?("KAIOS")
      end
    end
  end
end
