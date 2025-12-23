# frozen_string_literal: true

require "test_helper"

class HuaweiBrowserTest < Minitest::Test
  test "detects Huawei Browser" do
    browser = Browser.new(Browser["HUAWEI_BROWSER"])
    assert browser.huawei_browser?
    refute browser.safari?
    refute browser.chrome?
    assert_equal "Huawei Browser", browser.name
    assert_equal :huawei_browser, browser.id
  end

  test "detects correct version" do
    browser = Browser.new(Browser["HUAWEI_BROWSER"])
    assert_equal "10.1.2.300", browser.full_version
    assert_equal "10", browser.version
  end

  test "detects version by range" do
    browser = Browser.new(Browser["HUAWEI_BROWSER"])
    assert browser.huawei_browser?(%w[>=10 <11])
  end
end
