require "test_helper"

class ErrorBufferTest < Minitest::Test
  class FakeError < StandardError
  end

  def test_captures_and_stores_exceptions_and_env
    eb = ScoutApm::ErrorService::ErrorBuffer.new(context)
    eb.capture(ex, env)
  end

  #### Helpers

  def context
    ScoutApm::AgentContext.new
  end

  def env
    {}
  end

  def ex(msg="Whoops")
    FakeError.new(msg)
  end
end