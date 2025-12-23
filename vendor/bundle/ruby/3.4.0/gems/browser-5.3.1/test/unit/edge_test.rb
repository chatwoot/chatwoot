# frozen_string_literal: true

require "test_helper"

class EdgeTest < ActionController::TestCase
  test "detects Microsoft Edge" do
    browser = Browser.new(Browser["MS_EDGE"])

    assert_equal :edge, browser.id
    assert_equal "Microsoft Edge", browser.name
    assert_equal "12.0", browser.full_version
    assert_equal "12", browser.version
    assert browser.platform.windows10?
    assert browser.edge?
    refute browser.webkit?
    refute browser.chrome?
    refute browser.safari?
    refute browser.device.mobile?
  end

  test "detects Microsoft Edge in compatibility view" do
    browser = Browser.new(Browser["MS_EDGE_COMPAT"])

    assert_equal :edge, browser.id
    assert_equal "Microsoft Edge", browser.name
    assert_equal "12.0", browser.full_version
    assert_equal "12", browser.version
    assert_equal "7.0", browser.msie_full_version
    assert_equal "7", browser.msie_version
    assert browser.edge?
    assert browser.compatibility_view?
    refute browser.webkit?
    refute browser.chrome?
    refute browser.safari?
    refute browser.device.mobile?
  end

  test "detects Microsoft Edge Mobile" do
    browser = Browser.new(Browser["MS_EDGE_MOBILE"])

    assert_equal :edge, browser.id
    assert_equal "Microsoft Edge", browser.name
    assert_equal "12.0", browser.full_version
    assert_equal "12", browser.version
    refute browser.platform.windows10?
    assert browser.platform.windows_phone?
    assert browser.edge?
    refute browser.webkit?
    refute browser.chrome?
    refute browser.safari?
  end

  test "detects Microsoft Edge based on Chrome" do
    browser = Browser.new(Browser["MS_EDGE_CHROME"])

    assert_equal :edge, browser.id
    assert_equal "Microsoft Edge", browser.name
    assert_equal "79.0.309.18", browser.full_version
    assert_equal "79", browser.version
    assert browser.platform.mac?
    refute browser.platform.windows?
    assert browser.edge?
    assert browser.webkit?
    refute browser.chrome?
    refute browser.safari?
  end

  test "detects Microsoft Edge Mobile on iOS" do
    browser = Browser.new(Browser["MS_EDGE_IOS"])

    assert_equal :edge, browser.id
    assert_equal "Microsoft Edge", browser.name
    assert_equal "44.5.0.10", browser.full_version
    assert_equal "44", browser.version
    refute browser.platform.windows10?
    refute browser.platform.windows_phone?
    assert browser.platform.ios?
    assert browser.edge?
    refute browser.webkit?
    refute browser.chrome?
    refute browser.safari?
  end

  test "detects Microsoft Edge Mobile on Android" do
    browser = Browser.new(Browser["MS_EDGE_ANDROID"])

    assert_equal :edge, browser.id
    assert_equal "Microsoft Edge", browser.name
    assert_equal "44.11.2.4122", browser.full_version
    assert_equal "44", browser.version
    refute browser.platform.windows10?
    refute browser.platform.windows_phone?
    assert browser.platform.android?
    assert browser.edge?
    refute browser.webkit?
    refute browser.chrome?
    refute browser.safari?
  end

  test "detects version by range" do
    browser = Browser.new(Browser["MS_EDGE_IOS"])
    assert browser.edge?(%w[>=43 <45])
  end
end
