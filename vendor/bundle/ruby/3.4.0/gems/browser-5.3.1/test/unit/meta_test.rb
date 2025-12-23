# frozen_string_literal: true

require "test_helper"

class MetaTest < Minitest::Test
  class CustomRule < Browser::Meta::Base
    def meta
      "custom" if /Custom/.match?(browser.ua)
    end
  end

  test "extend rules" do
    Browser::Meta.rules.unshift(CustomRule)

    browser = Browser.new("Custom")
    assert browser.meta.include?("custom")

    browser = Browser.new("Safari")
    refute browser.meta.include?("custom")

    Browser::Meta.rules.shift

    browser = Browser.new("Custom")
    refute browser.meta.include?("custom")
  end

  test "sets meta" do
    browser = Browser.new(Browser["CHROME"])
    assert_kind_of Array, browser.meta
  end

  test "returns string representation" do
    browser = Browser.new(Browser["CHROME"])
    meta = browser.to_s

    assert meta.include?("chrome")
    assert meta.include?("webkit")
    assert meta.include?("mac")
  end

  test "returns string representation for mobile" do
    browser = Browser.new(Browser["BLACKBERRY"])
    meta = browser.to_s

    assert meta.include?("blackberry")
    assert meta.include?("mobile")
  end

  test "returns string representation for unknown platform/device/browser" do
    browser = Browser.new("Unknown")
    meta = browser.to_s

    assert meta.include?("unknown_platform")
    assert meta.include?("unknown_device")
    assert meta.include?("unknown_browser")
  end
end
