# frozen_string_literal: true

module Browser
  class Bot
    GENERIC_NAME = "Generic Bot"

    def self.matchers
      @matchers ||= default_matchers
    end

    def self.default_matchers
      [
        EmptyUserAgentMatcher,
        KnownBotsMatcher,
        KeywordMatcher
      ]
    end

    def self.load_yaml(path)
      YAML.load_file(Browser.root.join(path))
    end

    def self.bots
      @bots ||= load_yaml("bots.yml")
    end

    def self.bot_exceptions
      @bot_exceptions ||= load_yaml("bot_exceptions.yml")
    end

    def self.search_engines
      @search_engines ||= load_yaml("search_engines.yml")
    end

    def self.why?(ua)
      ua = ua.downcase.strip
      browser = Browser.new(ua)
      matchers.find {|matcher| matcher.call(ua, browser) }
    end

    attr_reader :ua, :browser

    def initialize(ua)
      @ua = ua.downcase.strip
      @browser = Browser.new(@ua)
    end

    def bot?
      !bot_exception? && detect_bot?
    end

    def why?
      self.class.matchers.find {|matcher| matcher.call(ua, self) }
    end

    def search_engine?
      self.class.search_engines.any? {|key, _| ua.include?(key) }
    end

    def name
      return unless bot?

      self.class.bots.find {|key, _| ua.include?(key) }&.last || GENERIC_NAME
    end

    private def bot_exception?
      self.class.bot_exceptions.any? {|key| ua.include?(key) }
    end

    private def detect_bot?
      self.class.matchers.any? {|matcher| matcher.call(ua, browser) }
    end

    private :ua
    private :browser
  end
end
