# frozen_string_literal: true

require "test_helper"

class SougouBrowserTest < Minitest::Test
  test "detects Sougou Browser on desktop device" do
    browser = Browser.new(Browser["SOUGOU_BROWSER"])
    assert browser.sougou_browser?
    refute browser.safari?
    refute browser.chrome?
    assert_equal "Sougou Browser", browser.name
    assert_equal :sougou_browser, browser.id
  end

  test "detects correct version on desktop device" do
    browser = Browser.new(Browser["SOUGOU_BROWSER"])
    assert_equal "0.0", browser.full_version
    assert_equal "0", browser.version
  end

  test "detects Sougou Browser on mobile device" do
    browser = Browser.new(Browser["SOUGOU_BROWSER_MOBILE"])
    assert browser.sougou_browser?
    assert browser.device.mobile?
    refute browser.safari?
    refute browser.chrome?
    assert_equal "Sougou Browser", browser.name
    assert_equal :sougou_browser, browser.id
  end

  test "detects correct version on mobile device" do
    browser = Browser.new(Browser["SOUGOU_BROWSER_MOBILE"])
    assert_equal "5.28.12", browser.full_version
    assert_equal "5", browser.version
  end

  test "detects version by range on mobile device" do
    browser = Browser.new(Browser["SOUGOU_BROWSER_MOBILE"])
    assert browser.sougou_browser?(%w[>=5 <6])
  end
end
