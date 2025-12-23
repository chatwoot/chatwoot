# frozen_string_literal: true

require "test_helper"

class MiuiBrowserTest < Minitest::Test
  test "detects Miui Browser" do
    browser = Browser.new(Browser["MIUI_BROWSER"])
    assert browser.miui_browser?
    refute browser.safari?
    refute browser.chrome?
    assert_equal "Miui Browser", browser.name
    assert_equal :miui_browser, browser.id
  end

  test "detects correct version" do
    browser = Browser.new(Browser["MIUI_BROWSER"])
    assert_equal "12.3.3", browser.full_version
    assert_equal "12", browser.version
  end

  test "detects version by range" do
    browser = Browser.new(Browser["MIUI_BROWSER"])
    assert browser.miui_browser?(%w[>=12 <13])
  end
end
