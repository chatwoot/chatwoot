# frozen_string_literal: true

module Browser
  class Device
    class Switch < Base
      def id
        :switch
      end

      def name
        "Nintendo Switch"
      end

      def match?
        ua.match?(/Nintendo Switch/i)
      end
    end
  end
end
