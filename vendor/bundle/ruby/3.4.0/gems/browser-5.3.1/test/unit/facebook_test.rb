# frozen_string_literal: true

require "test_helper"

class FacebookTest < Minitest::Test
  test "detects facebook" do
    browser = Browser.new(Browser["FACEBOOK"])

    assert_equal "Facebook", browser.name
    assert browser.facebook?
    assert :facebook, browser.id
    assert_equal "135.0.0.45.90", browser.full_version
    assert_equal "135", browser.version
  end

  test "detects new facebook on iOS" do
    browser = Browser.new(Browser["FACEBOOK_IOS"])

    assert_equal "Facebook", browser.name
    assert browser.facebook?
    assert :facebook, browser.id
    assert_equal "AppleWebKit/605.1.15", browser.full_version
    assert_equal "AppleWebKit/605", browser.version
  end

  test "detects new facebook on Android" do
    browser = Browser.new(Browser["FACEBOOK_ANDROID"])

    assert_equal "Facebook", browser.name
    assert browser.facebook?
    assert :facebook, browser.id
    assert_equal "214.0.0.43.83", browser.full_version
    assert_equal "214", browser.version
  end

  test "detects version by range" do
    browser = Browser.new(Browser["FACEBOOK"])
    assert browser.facebook?(%w[>=135])
  end
end
