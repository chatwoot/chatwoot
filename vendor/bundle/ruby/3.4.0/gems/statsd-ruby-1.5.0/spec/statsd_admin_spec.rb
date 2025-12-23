require 'helper'

describe Statsd::Admin do

  before do
    class Statsd::Admin
      o, $VERBOSE = $VERBOSE, nil
      alias connect_old connect
      def connect
        $connect_count ||= 0
        $connect_count += 1
      end
      $VERBOSE = o
    end
    @admin = Statsd::Admin.new('localhost', 1234)
    @socket = @admin.instance_variable_set(:@socket, FakeTCPSocket.new)
  end

  after do
    class Statsd::Admin
      o, $VERBOSE = $VERBOSE, nil
      alias connect connect_old
      $VERBOSE = o
    end
  end

  describe "#initialize" do
    it "should set the host and port" do
      _(@admin.host).must_equal 'localhost'
      _(@admin.port).must_equal 1234
    end

    it "should default the host to 127.0.0.1 and port to 8126" do
      statsd = Statsd::Admin.new
      _(statsd.host).must_equal '127.0.0.1'
      _(statsd.port).must_equal 8126
    end
  end

  describe "#host and #port" do
    it "should set host and port" do
      @admin.host = '1.2.3.4'
      @admin.port = 5678
      _(@admin.host).must_equal '1.2.3.4'
      _(@admin.port).must_equal 5678
    end

    it "should not resolve hostnames to IPs" do
      @admin.host = 'localhost'
      _(@admin.host).must_equal 'localhost'
    end

    it "should set nil host to default" do
      @admin.host = nil
      _(@admin.host).must_equal '127.0.0.1'
    end

    it "should set nil port to default" do
      @admin.port = nil
      _(@admin.port).must_equal 8126
    end
  end

  %w(gauges counters timers).each do |action|
    describe "##{action}" do
      it "should send a command and return a Hash" do
        ["{'foo.bar': 0,\n",
          "'foo.baz': 1,\n",
          "'foo.quux': 2 }\n",
          "END\n","\n"].each do |line|
          @socket.write line
        end
        result = @admin.send action.to_sym
        _(result).must_be_kind_of Hash
        _(result.size).must_equal 3
        _(@socket.readline).must_equal "#{action}\n"
      end
    end

    describe "#del#{action}" do
      it "should send a command and return an Array" do
        ["deleted: foo.bar\n",
         "deleted: foo.baz\n",
         "deleted: foo.quux\n",
          "END\n", "\n"].each do |line|
          @socket.write line
        end
        result = @admin.send "del#{action}", "foo.*"
        _(result).must_be_kind_of Array
        _(result.size).must_equal 3
        _(@socket.readline).must_equal "del#{action} foo.*\n"
      end
    end
  end

  describe "#stats" do
    it "should send a command and return a Hash" do
      ["whatever: 0\n", "END\n", "\n"].each do |line| 
        @socket.write line
      end
      result = @admin.stats
      _(result).must_be_kind_of Hash
      _(result["whatever"]).must_equal 0
      _(@socket.readline).must_equal "stats\n"
    end
  end

  describe "#connect" do
    it "should reconnect" do
      c = $connect_count
      @admin.connect
      _(($connect_count - c)).must_equal 1
    end
  end
end


