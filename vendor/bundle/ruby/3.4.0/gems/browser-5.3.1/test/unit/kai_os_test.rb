# frozen_string_literal: true

require "test_helper"

class KaiOSTest < Minitest::Test
  test "detects KaiOS" do
    browser = Browser.new(Browser["NOKIA_8110"])

    assert browser.firefox?
    assert_equal "48", browser.version
    assert_equal "48.0", browser.full_version
    assert_equal "Firefox", browser.name
    assert browser.platform.kai_os?
    assert_equal "KaiOS", browser.platform.name
    assert_equal "2.5", browser.platform.version
    refute browser.platform.android?
  end

  test "detects KaiOS with Android string in user-agent " do
    browser = Browser.new(Browser["JIOPHONE_2"])

    assert browser.firefox?
    assert_equal "48", browser.version
    assert_equal "48.0", browser.full_version
    assert_equal "Firefox", browser.name
    assert browser.platform.kai_os?
    assert_equal "KaiOS", browser.platform.name
    assert_equal "2.5", browser.platform.version
    refute browser.platform.android?
  end
end
