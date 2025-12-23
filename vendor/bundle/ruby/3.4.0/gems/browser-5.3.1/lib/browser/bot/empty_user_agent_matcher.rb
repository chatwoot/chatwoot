# frozen_string_literal: true

module Browser
  class Bot
    class EmptyUserAgentMatcher
      def self.call(ua, _browser)
        ua == ""
      end
    end
  end
end
