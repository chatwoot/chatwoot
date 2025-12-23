require 'test_helper'

class RouterTest < Minitest::Test
  def test_router_handles_record
    recorder = stub
    router = ScoutApm::Remote::Router.new(recorder, logger)
    message = ScoutApm::Remote::Message.new("record", "foo", 1, 2).encode

    recorder.expects(:foo).with(1, 2)

    router.handle(message)
  end

  def test_router_raises_on_unknown_types
    recorder = stub
    router = ScoutApm::Remote::Router.new(recorder, logger)
    message = ScoutApm::Remote::Message.new("something_else", "foo", 1, 2).encode

    recorder.expects(:foo).never
    assert_raises do
      router.handle(message)
    end
  end

  def logger
    @logger ||= Logger.new(logger_io)
  end

  def logger_io
    @logger_io ||= StringIO.new
  end
end

