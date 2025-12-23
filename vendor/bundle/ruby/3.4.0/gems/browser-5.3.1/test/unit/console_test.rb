# frozen_string_literal: true

require "test_helper"

class ConsoleTest < Minitest::Test
  test "detects psp" do
    browser = Browser.new(Browser["PSP"])
    assert_equal "Unknown Browser", browser.name
  end

  test "detects psp vita" do
    browser = Browser.new(Browser["PSP_VITA"])
    assert_equal "Unknown Browser", browser.name
  end
end
