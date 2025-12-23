# frozen_string_literal: true

require "test_helper"

class GoogleSearchAppTest < Minitest::Test
  test "detects Google Search App (Android)" do
    browser = Browser.new(Browser["GOOGLE_SEARCH_APP_ANDROID"])

    assert browser.webkit?
    assert browser.google_search_app?
    assert browser.platform.android?
    assert_equal :google_search_app, browser.id
    assert_equal "11", browser.version
    assert_equal "11.6.8.21", browser.full_version
    assert_equal "Google Search App", browser.name
    refute browser.chrome?
    refute browser.safari?
  end

  test "detects Google Search App (iPad)" do
    browser = Browser.new(Browser["GOOGLE_SEARCH_APP_IPAD"])

    assert browser.webkit?
    assert browser.google_search_app?
    assert browser.device.ipad?
    assert browser.platform.ios?
    assert_equal :google_search_app, browser.id
    assert_equal "102", browser.version
    assert_equal "102.0.304944559", browser.full_version
    assert_equal "Google Search App", browser.name
    refute browser.chrome?
    refute browser.safari?
  end

  test "detects Google Search App (iPhone)" do
    browser = Browser.new(Browser["GOOGLE_SEARCH_APP_IPHONE"])

    assert browser.webkit?
    assert browser.google_search_app?
    assert browser.device.iphone?
    assert browser.platform.ios?
    assert_equal :google_search_app, browser.id
    assert_equal "105", browser.version
    assert_equal "105.0.307913796", browser.full_version
    assert_equal "Google Search App", browser.name
    refute browser.chrome?
    refute browser.safari?
  end

  test "detects version by range (iPad)" do
    browser = Browser.new(Browser["GOOGLE_SEARCH_APP_IPAD"])
    assert browser.google_search_app?(%w[>=102 <103])
  end
end
