# frozen_string_literal: true

module Browser
  class Device
    class Ipad < Base
      def id
        :ipad
      end

      def name
        "iPad"
      end

      def match?
        ua.include?("iPad")
      end
    end
  end
end
