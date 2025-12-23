# frozen_string_literal: true

require "test_helper"

class SamsungBrowserTest < Minitest::Test
  test "detects samsung browser" do
    browser = Browser.new(Browser["SAMSUNG_BROWSER"])

    assert browser.webkit?
    assert browser.samsung_browser?
    assert_equal "11", browser.version
    assert_equal :samsung_browser, browser.id
    assert_equal "11.1", browser.full_version
    assert_equal "Samsung Browser", browser.name
    refute browser.chrome?
    refute browser.safari?
  end

  test "detects version by range" do
    browser = Browser.new(Browser["SAMSUNG_BROWSER"])
    assert browser.samsung_browser?(%w[>=11 <12])
  end
end
