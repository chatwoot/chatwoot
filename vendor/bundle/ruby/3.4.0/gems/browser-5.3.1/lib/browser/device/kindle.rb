# frozen_string_literal: true

module Browser
  class Device
    class Kindle < Base
      def id
        :kindle
      end

      def name
        "Kindle"
      end

      def match?
        ua.include?("Kindle")
      end
    end
  end
end
