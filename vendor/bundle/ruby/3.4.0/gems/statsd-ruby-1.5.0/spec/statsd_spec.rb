require 'helper'

describe Statsd do
  before do
    class Statsd
      o, $VERBOSE = $VERBOSE, nil
      alias connect_old connect
      def connect
        $connect_count ||= 1
        $connect_count += 1
      end
      $VERBOSE = o
    end

    @statsd = Statsd.new('localhost', 1234)
    @socket = @statsd.instance_variable_set(:@socket, FakeUDPSocket.new)
  end

  after do
    class Statsd
      o, $VERBOSE = $VERBOSE, nil
      alias connect connect_old
      $VERBOSE = o
    end
  end

  describe "#initialize" do
    it "should set the host and port" do
      _(@statsd.host).must_equal 'localhost'
      _(@statsd.port).must_equal 1234
    end

    it "should default the host to 127.0.0.1 and port to 8125" do
      statsd = Statsd.new
      _(statsd.host).must_equal '127.0.0.1'
      _(statsd.port).must_equal 8125
    end

    it "should set delimiter to period by default" do
      _(@statsd.delimiter).must_equal "."
    end
  end

  describe "#host and #port" do
    it "should set host and port" do
      @statsd.host = '1.2.3.4'
      @statsd.port = 5678
      _(@statsd.host).must_equal '1.2.3.4'
      _(@statsd.port).must_equal 5678
    end

    it "should not resolve hostnames to IPs" do
      @statsd.host = 'localhost'
      _(@statsd.host).must_equal 'localhost'
    end

    it "should set nil host to default" do
      @statsd.host = nil
      _(@statsd.host).must_equal '127.0.0.1'
    end

    it "should set nil port to default" do
      @statsd.port = nil
      _(@statsd.port).must_equal 8125
    end

    it "should allow an IPv6 address" do
      @statsd.host = '::1'
      _(@statsd.host).must_equal '::1'
    end
  end

  describe "#delimiter" do
    it "should set delimiter" do
      @statsd.delimiter = "-"
      _(@statsd.delimiter).must_equal "-"
    end

    it "should set default to period if not given a value" do
      @statsd.delimiter = nil
      _(@statsd.delimiter).must_equal "."
    end
  end

  describe "#increment" do
    it "should format the message according to the statsd spec" do
      @statsd.increment('foobar')
      _(@socket.recv).must_equal ['foobar:1|c']
    end

    describe "with a sample rate" do
      before { class << @statsd; def rand; 0; end; end } # ensure delivery
      it "should format the message according to the statsd spec" do
        @statsd.increment('foobar', 0.5)
        _(@socket.recv).must_equal ['foobar:1|c|@0.5']
      end
    end
  end

  describe "#decrement" do
    it "should format the message according to the statsd spec" do
      @statsd.decrement('foobar')
      _(@socket.recv).must_equal ['foobar:-1|c']
    end

    describe "with a sample rate" do
      before { class << @statsd; def rand; 0; end; end } # ensure delivery
      it "should format the message according to the statsd spec" do
        @statsd.decrement('foobar', 0.5)
        _(@socket.recv).must_equal ['foobar:-1|c|@0.5']
      end
    end
  end

  describe "#gauge" do
    it "should send a message with a 'g' type, per the nearbuy fork" do
      @statsd.gauge('begrutten-suffusion', 536)
      _(@socket.recv).must_equal ['begrutten-suffusion:536|g']
      @statsd.gauge('begrutten-suffusion', -107.3)
      _(@socket.recv).must_equal ['begrutten-suffusion:-107.3|g']
    end

    describe "with a sample rate" do
      before { class << @statsd; def rand; 0; end; end } # ensure delivery
      it "should format the message according to the statsd spec" do
        @statsd.gauge('begrutten-suffusion', 536, 0.1)
        _(@socket.recv).must_equal ['begrutten-suffusion:536|g|@0.1']
      end
    end
  end

  describe "#timing" do
    it "should format the message according to the statsd spec" do
      @statsd.timing('foobar', 500)
      _(@socket.recv).must_equal ['foobar:500|ms']
    end

    describe "with a sample rate" do
      before { class << @statsd; def rand; 0; end; end } # ensure delivery
      it "should format the message according to the statsd spec" do
        @statsd.timing('foobar', 500, 0.5)
        _(@socket.recv).must_equal ['foobar:500|ms|@0.5']
      end
    end
  end

  describe "#set" do
    it "should format the message according to the statsd spec" do
      @statsd.set('foobar', 765)
      _(@socket.recv).must_equal ['foobar:765|s']
    end

    describe "with a sample rate" do
      before { class << @statsd; def rand; 0; end; end } # ensure delivery
      it "should format the message according to the statsd spec" do
        @statsd.set('foobar', 500, 0.5)
        _(@socket.recv).must_equal ['foobar:500|s|@0.5']
      end
    end
  end

  describe "#time" do
    it "should format the message according to the statsd spec" do
      @statsd.time('foobar') { 'test' }
      _(@socket.recv).must_equal ['foobar:0|ms']
    end

    it "should return the result of the block" do
      result = @statsd.time('foobar') { 'test' }
      _(result).must_equal 'test'
    end

    describe "when given a block with an explicit return" do
      it "should format the message according to the statsd spec" do
        lambda { @statsd.time('foobar') { return 'test' } }.call
        _(@socket.recv).must_equal ['foobar:0|ms']
      end

      it "should return the result of the block" do
        result = lambda { @statsd.time('foobar') { return 'test' } }.call
        _(result).must_equal 'test'
      end
    end

    describe "with a sample rate" do
      before { class << @statsd; def rand; 0; end; end } # ensure delivery

      it "should format the message according to the statsd spec" do
        @statsd.time('foobar', 0.5) { 'test' }
        _(@socket.recv).must_equal ['foobar:0|ms|@0.5']
      end
    end
  end

  describe "#sampled" do
    describe "when the sample rate is 1" do
      before { class << @statsd; def rand; raise end; end }
      it "should send" do
        @statsd.timing('foobar', 500, 1)
        _(@socket.recv).must_equal ['foobar:500|ms']
      end
    end

    describe "when the sample rate is greater than a random value [0,1]" do
      before { class << @statsd; def rand; 0; end; end } # ensure delivery
      it "should send" do
        @statsd.timing('foobar', 500, 0.5)
        _(@socket.recv).must_equal ['foobar:500|ms|@0.5']
      end
    end

    describe "when the sample rate is less than a random value [0,1]" do
      before { class << @statsd; def rand; 1; end; end } # ensure no delivery
      it "should not send" do
        assert_nil @statsd.timing('foobar', 500, 0.5)
      end
    end

    describe "when the sample rate is equal to a random value [0,1]" do
      before { class << @statsd; def rand; 0; end; end } # ensure delivery
      it "should send" do
        @statsd.timing('foobar', 500, 0.5)
        _(@socket.recv).must_equal ['foobar:500|ms|@0.5']
      end
    end
  end

  describe "with namespace" do
    before { @statsd.namespace = 'service' }

    it "should add namespace to increment" do
      @statsd.increment('foobar')
      _(@socket.recv).must_equal ['service.foobar:1|c']
    end

    it "should add namespace to decrement" do
      @statsd.decrement('foobar')
      _(@socket.recv).must_equal ['service.foobar:-1|c']
    end

    it "should add namespace to timing" do
      @statsd.timing('foobar', 500)
      _(@socket.recv).must_equal ['service.foobar:500|ms']
    end

    it "should add namespace to gauge" do
      @statsd.gauge('foobar', 500)
      _(@socket.recv).must_equal ['service.foobar:500|g']
    end
  end

  describe "with postfix" do
    before { @statsd.postfix = 'ip-23-45-56-78' }

    it "should add postfix to increment" do
      @statsd.increment('foobar')
      _(@socket.recv).must_equal ['foobar.ip-23-45-56-78:1|c']
    end

    it "should add postfix to decrement" do
      @statsd.decrement('foobar')
      _(@socket.recv).must_equal ['foobar.ip-23-45-56-78:-1|c']
    end

    it "should add namespace to timing" do
      @statsd.timing('foobar', 500)
      _(@socket.recv).must_equal ['foobar.ip-23-45-56-78:500|ms']
    end

    it "should add namespace to gauge" do
      @statsd.gauge('foobar', 500)
      _(@socket.recv).must_equal ['foobar.ip-23-45-56-78:500|g']
    end
  end

  describe '#postfix=' do
    describe "when nil, false, or empty" do
      it "should set postfix to nil" do
        [nil, false, ''].each do |value|
          @statsd.postfix = 'a postfix'
          @statsd.postfix = value
          assert_nil @statsd.postfix
        end
      end
    end
  end

  describe "with logging" do
    require 'stringio'
    before { Statsd.logger = Logger.new(@log = StringIO.new)}

    it "should write to the log in debug" do
      Statsd.logger.level = Logger::DEBUG

      @statsd.increment('foobar')

      _(@log.string).must_match "Statsd: foobar:1|c"
    end

    it "should not write to the log unless debug" do
      Statsd.logger.level = Logger::INFO

      @statsd.increment('foobar')

      _(@log.string).must_be_empty
    end
  end

  describe "stat names" do
    it "should accept anything as stat" do
      @statsd.increment(Object, 1)
    end

    it "should replace ruby constant delimeter with graphite package name" do
      class Statsd::SomeClass; end
      @statsd.increment(Statsd::SomeClass, 1)

      _(@socket.recv).must_equal ['Statsd.SomeClass:1|c']
    end

    describe "custom delimiter" do
      before do
        @statsd.delimiter = "-"
      end

      it "should replace ruby constant delimiter with custom delimiter" do
        class Statsd::SomeOtherClass; end
        @statsd.increment(Statsd::SomeOtherClass, 1)

        _(@socket.recv).must_equal ['Statsd-SomeOtherClass:1|c']
      end
    end

    it "should replace statsd reserved chars in the stat name" do
      @statsd.increment('ray@hostname.blah|blah.blah:blah', 1)
      _(@socket.recv).must_equal ['ray_hostname.blah_blah.blah_blah:1|c']
    end
  end

  describe "handling socket errors" do
    before do
      require 'stringio'
      Statsd.logger = Logger.new(@log = StringIO.new)
      @socket.instance_variable_set(:@err_count, 0)
      @socket.instance_eval { def write(*) @err_count+=1; raise SocketError end }
    end

    it "should ignore socket errors" do
      assert_nil @statsd.increment('foobar')
    end

    it "should log socket errors" do
      @statsd.increment('foobar')
      _(@log.string).must_match 'Statsd: SocketError'
    end

    it "should retry and reconnect on socket errors" do
      $connect_count = 0
      @statsd.increment('foobar')
      _(@socket.instance_variable_get(:@err_count)).must_equal 5
      _($connect_count).must_equal 5
    end
  end

  describe "batching" do
    it "should have a default batch size of 10" do
      _(@statsd.batch_size).must_equal 10
    end

    it "should have a default batch byte size of nil" do
      assert_nil @statsd.batch_byte_size
    end

    it "should have a default flush interval of nil" do
      assert_nil @statsd.flush_interval
    end

    it "should have a modifiable batch size" do
      @statsd.batch_size = 7
      _(@statsd.batch_size).must_equal 7
      @statsd.batch do |b|
        _(b.batch_size).must_equal 7
      end

      @statsd.batch_size = nil
      @statsd.batch_byte_size = 1472
      @statsd.batch do |b|
        assert_nil b.batch_size
        _(b.batch_byte_size).must_equal 1472
      end

    end

    it 'should have a modifiable flush interval' do
      @statsd.flush_interval = 1
      _(@statsd.flush_interval).must_equal 1
      @statsd.batch do |b|
        _(b.flush_interval).must_equal 1
      end
    end

    it "should flush the batch at the batch size or at the end of the block" do
      @statsd.batch do |b|
        b.batch_size = 3

        # The first three should flush, the next two will be flushed when the
        # block is done.
        5.times { b.increment('foobar') }

        _(@socket.recv).must_equal [(["foobar:1|c"] * 3).join("\n")]
      end

      _(@socket.recv).must_equal [(["foobar:1|c"] * 2).join("\n")]
    end

    it "should flush based on batch byte size" do
      @statsd.batch do |b|
        b.batch_size = nil
        b.batch_byte_size = 22

        # The first two should flush, the last will be flushed when the
        # block is done.
        3.times { b.increment('foobar') }

        _(@socket.recv).must_equal [(["foobar:1|c"] * 2).join("\n")]
      end

      _(@socket.recv).must_equal ["foobar:1|c"]
    end

    it "should flush immediately when the queue is exactly a batch size" do
      @statsd.batch do |b|
        b.batch_size = nil
        b.batch_byte_size = 21

        # The first two should flush together
        2.times { b.increment('foobar') }

        _(@socket.recv).must_equal [(["foobar:1|c"] * 2).join("\n")]
      end
    end

    it "should flush when the interval has passed" do
      @statsd.batch do |b|
        b.batch_size = nil
        b.flush_interval = 0.01

        # The first two should flush, the last will be flushed when the
        # block is done.
        2.times { b.increment('foobar') }
        sleep(0.03)
        b.increment('foobar')

        _(@socket.recv).must_equal [(["foobar:1|c"] * 2).join("\n")]
      end

      _(@socket.recv).must_equal ["foobar:1|c"]
    end

    it "should not flush to the socket if the backlog is empty" do
      batch = Statsd::Batch.new(@statsd)
      batch.flush
      _(@socket.recv).must_be :nil?

      batch.increment 'foobar'
      batch.flush
      _(@socket.recv).must_equal %w[foobar:1|c]
    end

    it "should support setting namespace for the underlying instance" do
      batch = Statsd::Batch.new(@statsd)
      batch.namespace = 'ns'
      _(@statsd.namespace).must_equal 'ns'
    end

    it "should support setting host for the underlying instance" do
      batch = Statsd::Batch.new(@statsd)
      batch.host = '1.2.3.4'
      _(@statsd.host).must_equal '1.2.3.4'
    end

    it "should support setting port for the underlying instance" do
      batch = Statsd::Batch.new(@statsd)
      batch.port = 42
      _(@statsd.port).must_equal 42
    end

  end

  describe "#connect" do
    it "should reconnect" do
      c = $connect_count
      @statsd.connect
      _(($connect_count - c)).must_equal 1
    end
  end

end

describe Statsd do
  describe "with a real UDP socket" do
    it "should actually send stuff over the socket" do
      family = Addrinfo.udp(UDPSocket.getaddress('localhost'), 0).afamily
      begin
        socket = UDPSocket.new family
        host, port = 'localhost', 0
        socket.bind(host, port)
        port = socket.addr[1]

        statsd = Statsd.new(host, port)
        statsd.increment('foobar')
        message = socket.recvfrom(16).first
        _(message).must_equal 'foobar:1|c'
      ensure
        socket.close
      end
    end

    it "should send stuff over an IPv4 socket" do
      begin
        socket = UDPSocket.new Socket::AF_INET
        host, port = '127.0.0.1', 0
        socket.bind(host, port)
        port = socket.addr[1]

        statsd = Statsd.new(host, port)
        statsd.increment('foobar')
        message = socket.recvfrom(16).first
        _(message).must_equal 'foobar:1|c'
      ensure
        socket.close
      end
    end

    it "should send stuff over an IPv6 socket" do
      begin
        socket = UDPSocket.new Socket::AF_INET6
        host, port = '::1', 0
        socket.bind(host, port)
        port = socket.addr[1]

        statsd = Statsd.new(host, port)
        statsd.increment('foobar')
        message = socket.recvfrom(16).first
        _(message).must_equal 'foobar:1|c'
      ensure
        socket.close
      end
    end
  end

  describe "supports TCP sockets" do
    it "should connect to and send stats over TCPv4" do
      begin
        host, port = '127.0.0.1', 0
        server = TCPServer.new host, port
        port = server.addr[1]

        socket = nil
        Thread.new { socket = server.accept }

        statsd = Statsd.new(host, port, :tcp)
        statsd.increment('foobar')

        Timeout.timeout(5) do
          Thread.pass while socket == nil
        end

        message = socket.recvfrom(16).first
        _(message).must_equal "foobar:1|c\n"
      ensure
        socket.close if socket
        server.close
      end
    end

    it "should connect to and send stats over TCPv6" do
      begin
        host, port = '::1', 0
        server = TCPServer.new host, port
        port = server.addr[1]

        socket = nil
        Thread.new { socket = server.accept }

        statsd = Statsd.new(host, port, :tcp)
        statsd.increment('foobar')

        Timeout.timeout(5) do
          Thread.pass while socket == nil
        end

        message = socket.recvfrom(16).first
        _(message).must_equal "foobar:1|c\n"
      ensure
        socket.close if socket
        server.close
      end
    end
  end
end
