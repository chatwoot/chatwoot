require "test_helper"

class IgnoredExceptionsTest < Minitest::Test
  class FakeError < StandardError
  end

  class SubclassFakeError < FakeError
  end

  def test_ignores_with_string_match
    ig = ScoutApm::ErrorService::IgnoredExceptions.new(context, ["RuntimeError"])
    assert ig.ignored?(RuntimeError.new("something went wrong"))
    assert !ig.ignored?(FakeError.new("something went wrong"))
  end

  def test_ignores_with_block
    ig = ScoutApm::ErrorService::IgnoredExceptions.new(context, [])
    ig.add_callback { |e| e.message == "ignore me" }

    should_ignore = RuntimeError.new("ignore me")
    should_not_ignore = RuntimeError.new("super legit")

    assert ig.ignored?(should_ignore)
    assert !ig.ignored?(should_not_ignore)
  end

  def test_ignores_subclasses
    ig = ScoutApm::ErrorService::IgnoredExceptions.new(context, ["IgnoredExceptionsTest::FakeError"])
    assert ig.ignored?(SubclassFakeError.new("Subclass"))
  end

  # Check that a bad exception in the list doesn't stop the whole thing from working
  def test_does_not_consider_unknown_errors
    ig = ScoutApm::ErrorService::IgnoredExceptions.new(context, ["ThisDoesNotExist", "IgnoredExceptionsTest::FakeError"])
    assert ig.ignored?(FakeError.new("ignore this one"))
  end

  def test_add_module
    ig = ScoutApm::ErrorService::IgnoredExceptions.new(context, [])
    ig.add(IgnoredExceptionsTest::FakeError)
    assert ig.ignored?(FakeError.new("ignore this one"))
  end

  #### Helpers

  def context
    ScoutApm::AgentContext.new
  end
end