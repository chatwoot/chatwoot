# frozen_string_literal: true

require "test_helper"

class InstagramTest < Minitest::Test
  test "detects instagram" do
    browser = Browser.new(Browser["INSTAGRAM"])

    assert_equal "Instagram", browser.name
    assert browser.instagram?
    assert :instagram, browser.id
    assert_equal "41.0.0.14.90", browser.full_version
    assert_equal "41", browser.version
  end

  test "detects alternate instagram user agent" do
    browser = Browser.new(Browser["INSTAGRAM_OTHER"])

    assert_equal "Instagram", browser.name
    assert browser.instagram?
    assert :instagram, browser.id
    assert_equal "182257141", browser.full_version
    assert_equal "182257141", browser.version
  end

  test "detects version by range" do
    browser = Browser.new(Browser["INSTAGRAM"])
    assert browser.instagram?(%w[>=41])
  end
end
