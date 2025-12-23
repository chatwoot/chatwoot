# frozen_string_literal: true

require "test_helper"

class YandexTest < Minitest::Test
  test "detects Yandex on iOS device" do
    browser = Browser.new(Browser["YANDEX_BROWSER_IOS"])
    assert browser.yandex?
    assert browser.yandex_browser?
    refute browser.safari?
    refute browser.chrome?
    assert browser.webkit?
    assert_equal "Yandex", browser.name
    assert_equal :yandex, browser.id
  end

  test "detects Yandex on non-iOS devices" do
    browser = Browser.new(Browser["YANDEX_BROWSER_DESKTOP"])
    assert browser.yandex?
    assert browser.yandex_browser?
    refute browser.safari?
    refute browser.chrome?
    assert_equal "Yandex", browser.name
    assert_equal :yandex, browser.id
  end

  test "detects correct version" do
    browser = Browser.new(Browser["YANDEX_BROWSER_DESKTOP"])
    assert_equal "19.6.0.1583", browser.full_version
    assert_equal "19", browser.version
  end

  test "detects version by range" do
    browser = Browser.new(Browser["YANDEX_BROWSER_DESKTOP"])
    assert browser.yandex?(%w[>=18 <20])
  end
end
