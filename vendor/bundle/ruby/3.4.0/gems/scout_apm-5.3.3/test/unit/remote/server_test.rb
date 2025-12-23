require 'test_helper'

class TestRemoteServer < Minitest::Test
  def test_start_and_bind
    bind = "127.0.0.1"
    port = 8938
    router = stub(:router)
    logger_io = StringIO.new
    server = ScoutApm::Remote::Server.new(bind, port, router, Logger.new(logger_io))

    # Cannot test this if we can't require webrick. Ruby 3 stopped including by default
    skip unless server.require_webrick

    server.start
    sleep 0.05 # Let the server finish starting. The assert should instead allow a time
    assert server.running?
  end
end
