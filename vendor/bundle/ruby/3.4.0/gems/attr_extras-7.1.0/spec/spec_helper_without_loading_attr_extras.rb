require "minitest/autorun"
require "minitest/pride"

$: << File.dirname(__FILE__) + "/../lib"

Minitest::Test.class_eval do
  def refute_warnings_emitted(&block)
    _, stderr = capture_io(&block)

    assert stderr.empty?, -> do
      warnings = stderr.strip.split("\n").map { |line| "  #{line}" }.join("\n")
      "Expected no warnings to be emitted, but these ones were:\n\n#{warnings}"
    end
  end

  def refute_raises_anything
    yield
  rescue => error
    flunk "Expected no error to be raised, but got #{error.class} (#{error.message})."
  end
end
