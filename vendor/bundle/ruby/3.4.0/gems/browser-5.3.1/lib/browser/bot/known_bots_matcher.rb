# frozen_string_literal: true

module Browser
  class Bot
    class KnownBotsMatcher
      def self.call(ua, _browser)
        Browser::Bot.bots.any? {|key, _| ua.include?(key) }
      end
    end
  end
end
