# frozen_string_literal: true

require "test_helper"

class MicroMessengerTest < Minitest::Test
  test "detects micro messenger 7.0.10 on iOS" do
    browser = Browser.new(Browser["MICRO_MESSENGER_IOS"])

    assert browser.micro_messenger?
    assert browser.wechat?
    assert_equal "7.0.10", browser.full_version
    assert_equal "MicroMessenger", browser.name
    assert_equal :micro_messenger, browser.id
  end

  test "detects version by range on iOS" do
    browser = Browser.new(Browser["MICRO_MESSENGER_IOS"])
    assert browser.wechat?(%w[>=7 <8])
  end

  test "detects micro messenger 7.0.13.1640 on Android" do
    browser = Browser.new(Browser["MICRO_MESSENGER_ANDROID"])

    assert browser.micro_messenger?
    assert browser.wechat?
    assert_equal "7.0.13.1640", browser.full_version
    assert_equal "MicroMessenger", browser.name
    assert_equal :micro_messenger, browser.id
  end

  test "detects version by range on Android" do
    browser = Browser.new(Browser["MICRO_MESSENGER_ANDROID"])
    assert browser.wechat?(%w[>=7 <8])
  end
end
