# frozen_string_literal: true

require "test_helper"

class BotsTest < Minitest::Test
  Browser.bot_user_agents.each do |key, ua|
    test "detect #{key} as bot" do
      browser = Browser.new(ua)
      assert browser.bot?
    end
  end

  test "don't detect as bot" do
    browser = Browser.new(Browser["CHROME"])
    refute browser.bot?
  end

  test "returns bot name" do
    browser = Browser.new(Browser["GOOGLE_BOT"])
    assert_equal "Google Bot", browser.bot.name

    browser = Browser.new(Browser["FACEBOOK_BOT"])
    assert_equal "Facebook Bot", browser.bot.name
  end

  test "returns nil for non-bots" do
    browser = Browser.new(Browser["CHROME"])
    assert_nil browser.bot.name
  end

  Browser.search_engine_user_agents.each do |key, ua|
    test "detects #{key} as search engine" do
      browser = Browser.new(ua)
      assert browser.bot.search_engine?
    end
  end

  test "detects Daumoa" do
    browser = Browser.new(Browser["DAUMOA"])

    assert_equal :ie, browser.id
    assert_equal "Internet Explorer", browser.name
    assert_equal "0.0", browser.msie_full_version
    assert_equal "0", browser.msie_version
    assert_equal "0.0", browser.full_version
    assert_equal "0", browser.version
    assert browser.ie?
    assert browser.bot?
    refute browser.platform.windows10?
    refute browser.platform.windows_phone?
    refute browser.edge?
    refute browser.device.mobile?
    refute browser.webkit?
    refute browser.chrome?
    refute browser.safari?
  end

  test "custom android user agent (#144)" do
    browser = Browser.new(Browser["CUSTOM_APP"])

    assert browser.platform.android?
    refute browser.bot?
  end

  test "extends list in runtime" do
    browser = Browser.new("Faraday/0.9.2")
    refute browser.bot?

    Browser::Bot.bots["faraday"] = "Faraday"
    assert browser.bot?

    Browser::Bot.bots.delete("faraday")
  end

  test "detects recognized bots using common libs" do
    browser = Browser.new(Browser.bot_user_agents["LINKEDIN"])

    assert browser.bot?
    assert_equal "LinkedIn", browser.bot.name
  end

  test "tells why user agent is considered a bot" do
    matcher = Browser::Bot.why?(Browser.bot_user_agents["LINKEDIN"])

    assert_equal Browser::Bot::KnownBotsMatcher, matcher
  end

  test "adds custom bot matcher" do
    Browser::Bot.matchers << ->(ua, _) { ua.match?(/some-script/) }
    browser = Browser.new("some-script")

    assert browser.bot?
    assert_equal "Generic Bot", browser.bot.name
  end

  %w[
    content-fetcher
    content-crawler
    some-search-engine
    monitoring-service
    content-spider
    some-bot
  ].each do |ua|
    test "detects user agents based on keywords (#{ua})" do
      browser = Browser.new(ua)

      assert browser.bot?
      assert_equal Browser::Bot::KeywordMatcher, browser.bot.why?
    end
  end
end
