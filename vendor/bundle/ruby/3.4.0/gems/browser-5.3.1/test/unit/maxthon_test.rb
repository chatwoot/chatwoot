# frozen_string_literal: true

require "test_helper"

class MaxthonTest < Minitest::Test
  test "detects Maxthon" do
    browser = Browser.new(Browser["MAXTHON"])
    assert browser.maxthon?
    refute browser.safari?
    refute browser.chrome?
    assert_equal "Maxthon", browser.name
    assert_equal :maxthon, browser.id
  end

  test "detects correct version" do
    browser = Browser.new(Browser["MAXTHON"])
    assert_equal "5.3.8.2000", browser.full_version
    assert_equal "5", browser.version
  end

  test "detects version by range" do
    browser = Browser.new(Browser["MAXTHON"])
    assert browser.maxthon?(%w[>=5 <6])
  end
end
