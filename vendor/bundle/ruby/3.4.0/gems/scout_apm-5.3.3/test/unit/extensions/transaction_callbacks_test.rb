require 'test_helper'

class TransactionCallbacksTest < Minitest::Test

  def setup
    # Another test could set the recorder to +FakeRecorder+, which does not call +TrackedRequest#record!+.
    ScoutApm::Agent.instance.context.recorder = ScoutApm::RecorderFactory.build(ScoutApm::Agent.instance.context)
  end

  # This is more of an integration test to ensure that we don't break TrackedRequest.
  def test_broken_callback_does_not_break_tracked_request
    ScoutApm::Extensions::Config.add_transaction_callback(BrokenCallback.new)

    controller_layer = ScoutApm::Layer.new("Controller", "users/index")
    # why doesn't this run? check if callbacks are configured
    tr = ScoutApm::TrackedRequest.new(ScoutApm::Agent.instance.context, ScoutApm::FakeStore.new)
    tr.start_layer(controller_layer)
    tr.stop_layer
  end

  def test_callback_runs
    Thread.current[:transaction_callback_output] = nil
    ScoutApm::Extensions::Config.add_transaction_callback(TransactionCallback.new)

    controller_layer = ScoutApm::Layer.new("Controller", "users/index")

    tr = ScoutApm::TrackedRequest.new(ScoutApm::Agent.instance.context, ScoutApm::FakeStore.new)
    tr.start_layer(controller_layer)
    tr.stop_layer

    assert Thread.current[:transaction_callback_output]
  end

  def test_run_proc_callback
    Thread.current[:proc_transaction_duration] = nil
    ScoutApm::Extensions::Config.add_transaction_callback(Proc.new { |payload| Thread.current[:proc_transaction_duration] = payload.duration_ms })

    controller_layer = ScoutApm::Layer.new("Controller", "users/index")

    tr = ScoutApm::TrackedRequest.new(ScoutApm::Agent.instance.context, ScoutApm::FakeStore.new)
    tr.start_layer(controller_layer)
    tr.stop_layer

    assert Thread.current[:proc_transaction_duration]
  end

  # Doesn't respond to +call+.
  class BrokenCallback
  end

  # Sets a Thread local so we can verify that the callback ran.
  class TransactionCallback
    def call(payload)
      Thread.current[:transaction_callback_output] = true
    end
  end

end