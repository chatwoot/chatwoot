require 'test_helper'

class TransactionTest < Minitest::Test
  def test_ignore
    recorder = FakeRecorder.new
    ScoutApm::Agent.instance.context.recorder = recorder

    ScoutApm::Tracer.instrument("Controller", "foo/bar") do
      ScoutApm::Transaction.ignore!
    end

    assert_equal 0, recorder.requests.length
  end
end
