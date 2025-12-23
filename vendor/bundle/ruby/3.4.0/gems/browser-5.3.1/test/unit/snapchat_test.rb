# frozen_string_literal: true

require "test_helper"

class SnapchatTest < Minitest::Test
  test "detects snapchat" do
    browser = Browser.new(Browser["SNAPCHAT"])

    assert_equal "Snapchat", browser.name
    assert browser.snapchat?
    assert :snapchat, browser.id
    assert_equal "10.69.5.72", browser.full_version
    assert_equal "10", browser.version
  end

  test "detects snapchat for badly formatted user agent" do
    browser = Browser.new(Browser["SNAPCHAT_EMPTY_STRING_VERSION"])

    assert_equal "Snapchat", browser.name
    assert browser.snapchat?
    assert :snapchat, browser.id
    assert_equal "10.70.0.0", browser.full_version
    assert_equal "10", browser.version
  end

  test "detects alternate snapchat user agent" do
    browser = Browser.new(Browser["SNAPCHAT_SPACE_VERSION"])

    assert_equal "Snapchat", browser.name
    assert browser.snapchat?
    assert :snapchat, browser.id
    assert_equal "10.70.0.0", browser.full_version
    assert_equal "10", browser.version
  end

  test "detects version by range" do
    browser = Browser.new(Browser["SNAPCHAT"])
    assert browser.snapchat?(%w[>=10])
  end
end
