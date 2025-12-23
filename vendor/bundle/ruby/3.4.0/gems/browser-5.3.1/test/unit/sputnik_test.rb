# frozen_string_literal: true

require "test_helper"

class SputnikTest < Minitest::Test
  test "detects sputnik" do
    browser = Browser.new(Browser["SPUTNIK"])

    assert_equal "Sputnik", browser.name
    assert_equal :sputnik, browser.id
    assert browser.sputnik?
    refute browser.chrome?
    refute browser.safari?
    assert_equal "4.1.2801.0", browser.full_version
    assert_equal "4", browser.version
  end

  test "detects version by range" do
    browser = Browser.new(Browser["SPUTNIK"])
    assert browser.sputnik?(%w[>=4 <5])
  end
end
