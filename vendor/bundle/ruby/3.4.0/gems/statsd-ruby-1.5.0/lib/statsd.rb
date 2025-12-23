require 'socket'
require 'forwardable'
require 'json'

require 'statsd/monotonic_time'

# = Statsd: A Statsd client (https://github.com/etsy/statsd)
#
# @example Set up a global Statsd client for a server on localhost:8125
#   $statsd = Statsd.new 'localhost', 8125
# @example Set up a global Statsd client for a server on IPv6 port 8125
#   $statsd = Statsd.new '::1', 8125
# @example Send some stats
#   $statsd.increment 'garets'
#   $statsd.timing 'glork', 320
#   $statsd.gauge 'bork', 100
# @example Use {#time} to time the execution of a block
#   $statsd.time('account.activate') { @account.activate! }
# @example Create a namespaced statsd client and increment 'account.activate'
#   statsd = Statsd.new('localhost').tap{|sd| sd.namespace = 'account'}
#   statsd.increment 'activate'
#
# Statsd instances are thread safe for general usage, by utilizing the thread
# safe nature of UDP sends. The attributes are stateful, and are not
# mutexed, it is expected that users will not change these at runtime in
# threaded environments. If users require such use cases, it is recommend that
# users either mutex around their Statsd object, or create separate objects for
# each namespace / host+port combination.
class Statsd

  # = Batch: A batching statsd proxy
  #
  # @example Batch a set of instruments using Batch and manual flush:
  #   $statsd = Statsd.new 'localhost', 8125
  #   batch = Statsd::Batch.new($statsd)
  #   batch.increment 'garets'
  #   batch.timing 'glork', 320
  #   batch.gauge 'bork', 100
  #   batch.flush
  #
  # Batch is a subclass of Statsd, but with a constructor that proxies to a
  # normal Statsd instance. It has it's own batch_size and namespace parameters
  # (that inherit defaults from the supplied Statsd instance). It is recommended
  # that some care is taken if setting very large batch sizes. If the batch size
  # exceeds the allowed packet size for UDP on your network, communication
  # troubles may occur and data will be lost.
  class Batch < Statsd

    extend Forwardable
    def_delegators :@statsd,
      :namespace, :namespace=,
      :host, :host=,
      :port, :port=,
      :prefix,
      :postfix,
      :delimiter, :delimiter=

    attr_accessor :batch_size, :batch_byte_size, :flush_interval

    # @param [Statsd] statsd requires a configured Statsd instance
    def initialize(statsd)
      @statsd = statsd
      @batch_size = statsd.batch_size
      @batch_byte_size = statsd.batch_byte_size
      @flush_interval = statsd.flush_interval
      @backlog = []
      @backlog_bytesize = 0
      @last_flush = Time.now
    end

    # @yield [Batch] yields itself
    #
    # A convenience method to ensure that data is not lost in the event of an
    # exception being thrown. Batches will be transmitted on the parent socket
    # as soon as the batch is full, and when the block finishes.
    def easy
      yield self
    ensure
      flush
    end

    def flush
      unless @backlog.empty?
        @statsd.send_to_socket @backlog.join("\n")
        @backlog.clear
        @backlog_bytesize = 0
        @last_flush = Time.now
      end
    end

    protected

    def send_to_socket(message)
      # this message wouldn't fit; flush the queue. note that we don't have
      # to do this for message based flushing, because we're incrementing by
      # one, so the post-queue check will always catch it
      if (@batch_byte_size && @backlog_bytesize + message.bytesize + 1 > @batch_byte_size) ||
          (@flush_interval && last_flush_seconds_ago >= @flush_interval)
        flush
      end
      @backlog << message
      @backlog_bytesize += message.bytesize
      # skip the interleaved newline for the first item
      @backlog_bytesize += 1 if @backlog.length != 1
      # if we're precisely full now, flush
      if (@batch_size && @backlog.size == @batch_size) ||
          (@batch_byte_size && @backlog_bytesize == @batch_byte_size)
        flush
      end
    end

    def last_flush_seconds_ago
      Time.now - @last_flush
    end

  end

  class Admin
    # StatsD host. Defaults to 127.0.0.1.
    attr_reader :host

    # StatsD admin port. Defaults to 8126.
    attr_reader :port

    class << self
      # Set to a standard logger instance to enable debug logging.
      attr_accessor :logger
    end

    # @attribute [w] host.
    #   Users should call connect after changing this.
    def host=(host)
      @host = host || '127.0.0.1'
    end

    # @attribute [w] port.
    #   Users should call connect after changing this.
    def port=(port)
      @port = port || 8126
    end

    # @param [String] host your statsd host
    # @param [Integer] port your statsd port
    def initialize(host = '127.0.0.1', port = 8126)
      @host = host || '127.0.0.1'
      @port = port || 8126
      # protects @socket transactions
      @socket = nil
      @s_mu = Mutex.new
      connect
    end

    # Reads all gauges from StatsD.
    def gauges
      read_metric :gauges
    end

    # Reads all timers from StatsD.
    def timers
      read_metric :timers
    end

    # Reads all counters from StatsD.
    def counters
      read_metric :counters
    end

    # @param[String] item
    #   Deletes one or more gauges. Wildcards are allowed.
    def delgauges item
      delete_metric :gauges, item
    end

    # @param[String] item
    #   Deletes one or more timers. Wildcards are allowed.
    def deltimers item
      delete_metric :timers, item
    end

    # @param[String] item
    #   Deletes one or more counters. Wildcards are allowed.
    def delcounters item
      delete_metric :counters, item
    end

    def stats
      result = @s_mu.synchronize do
        # the format of "stats" isn't JSON, who knows why
        send_to_socket "stats"
        read_from_socket
      end
      items = {}
      result.split("\n").each do |line|
        key, val = line.chomp.split(": ")
        items[key] = val.to_i
      end
      items
    end

    # Reconnects the socket, for when the statsd address may have changed. Users
    # do not normally need to call this, but calling it may be appropriate when
    # reconfiguring a process (e.g. from HUP)
    def connect
      @s_mu.synchronize do
        begin
          @socket.flush rescue nil
          @socket.close if @socket
        rescue
          # Ignore socket errors on close.
        end
        @socket = TCPSocket.new(host, port)
      end
    end

    private

    def read_metric name
      result = @s_mu.synchronize do
        send_to_socket name
        read_from_socket
      end
      # for some reason, the reply looks like JSON, but isn't, quite
      JSON.parse result.gsub("'", "\"")
    end

    def delete_metric name, item
      result = @s_mu.synchronize do
        send_to_socket "del#{name} #{item}"
        read_from_socket
      end
      deleted = []
      result.split("\n").each do |line|
        deleted << line.chomp.split(": ")[-1]
      end
      deleted
    end

    def send_to_socket(message)
      self.class.logger.debug { "Statsd: #{message}" } if self.class.logger
      @socket.write(message.to_s + "\n")
    rescue => boom
      self.class.logger.error { "Statsd: #{boom.class} #{boom}" } if self.class.logger
      nil
    end


    def read_from_socket
      buffer = ""
      loop do
        line = @socket.readline
        break if line == "END\n"
        buffer += line
      end
      @socket.readline # clear the closing newline out of the socket
      buffer
    end
  end

  # A namespace to prepend to all statsd calls.
  attr_reader :namespace

  # StatsD host. Defaults to 127.0.0.1.
  attr_reader :host

  # StatsD port. Defaults to 8125.
  attr_reader :port

  # StatsD namespace prefix, generated from #namespace
  attr_reader :prefix

  # The default batch size for new batches. Set to nil to use batch_byte_size (default: 10)
  attr_accessor :batch_size

  # The default batch size, in bytes, for new batches (default: default nil; use batch_size)
  attr_accessor :batch_byte_size

  # The flush interval, in seconds, for new batches (default: nil)
  attr_accessor :flush_interval

  # a postfix to append to all metrics
  attr_reader :postfix

  # The replacement of :: on ruby module names when transformed to statsd metric names
  attr_reader :delimiter

  class << self
    # Set to a standard logger instance to enable debug logging.
    attr_accessor :logger
  end

  # @param [String] host your statsd host
  # @param [Integer] port your statsd port
  # @param [Symbol] protocol :tcp for TCP, :udp or any other value for UDP
  def initialize(host = '127.0.0.1', port = 8125, protocol = :udp)
    @host = host || '127.0.0.1'
    @port = port || 8125
    self.delimiter = "."
    @prefix = nil
    @batch_size = 10
    @batch_byte_size = nil
    @flush_interval = nil
    @postfix = nil
    @socket = nil
    @protocol = protocol || :udp
    @s_mu = Mutex.new
    connect
  end

  # @attribute [w] namespace
  #   Writes are not thread safe.
  def namespace=(namespace)
    @namespace = namespace
    @prefix = "#{namespace}."
  end

  # @attribute [w] postfix
  #   A value to be appended to the stat name after a '.'. If the value is
  #   blank then the postfix will be reset to nil (rather than to '.').
  def postfix=(pf)
    case pf
    when nil, false, '' then @postfix = nil
    else @postfix = ".#{pf}"
    end
  end

  # @attribute [w] host
  #   Writes are not thread safe.
  #   Users should call hup after making changes.
  def host=(host)
    @host = host || '127.0.0.1'
  end

  # @attribute [w] port
  #   Writes are not thread safe.
  #   Users should call hup after making changes.
  def port=(port)
    @port = port || 8125
  end

  # @attribute [w] stat_delimiter
  #   Allows for custom delimiter replacement for :: when Ruby modules are transformed to statsd metric name
  def delimiter=(delimiter)
    @delimiter = delimiter || "."
  end

  # Sends an increment (count = 1) for the given stat to the statsd server.
  #
  # @param [String] stat stat name
  # @param [Numeric] sample_rate sample rate, 1 for always
  # @see #count
  def increment(stat, sample_rate=1)
    count stat, 1, sample_rate
  end

  # Sends a decrement (count = -1) for the given stat to the statsd server.
  #
  # @param [String] stat stat name
  # @param [Numeric] sample_rate sample rate, 1 for always
  # @see #count
  def decrement(stat, sample_rate=1)
    count stat, -1, sample_rate
  end

  # Sends an arbitrary count for the given stat to the statsd server.
  #
  # @param [String] stat stat name
  # @param [Integer] count count
  # @param [Numeric] sample_rate sample rate, 1 for always
  def count(stat, count, sample_rate=1)
    send_stats stat, count, :c, sample_rate
  end

  # Sends an arbitary gauge value for the given stat to the statsd server.
  #
  # This is useful for recording things like available disk space,
  # memory usage, and the like, which have different semantics than
  # counters.
  #
  # @param [String] stat stat name.
  # @param [Numeric] value gauge value.
  # @param [Numeric] sample_rate sample rate, 1 for always
  # @example Report the current user count:
  #   $statsd.gauge('user.count', User.count)
  def gauge(stat, value, sample_rate=1)
    send_stats stat, value, :g, sample_rate
  end

  # Sends an arbitary set value for the given stat to the statsd server.
  #
  # This is for recording counts of unique events, which are useful to
  # see on graphs to correlate to other values.  For example, a deployment
  # might get recorded as a set, and be drawn as annotations on a CPU history
  # graph.
  #
  # @param [String] stat stat name.
  # @param [Numeric] value event value.
  # @param [Numeric] sample_rate sample rate, 1 for always
  # @example Report a deployment happening:
  #   $statsd.set('deployment', DEPLOYMENT_EVENT_CODE)
  def set(stat, value, sample_rate=1)
    send_stats stat, value, :s, sample_rate
  end

  # Sends a timing (in ms) for the given stat to the statsd server. The
  # sample_rate determines what percentage of the time this report is sent. The
  # statsd server then uses the sample_rate to correctly track the average
  # timing for the stat.
  #
  # @param [String] stat stat name
  # @param [Integer] ms timing in milliseconds
  # @param [Numeric] sample_rate sample rate, 1 for always
  def timing(stat, ms, sample_rate=1)
    send_stats stat, ms, :ms, sample_rate
  end

  # Reports execution time of the provided block using {#timing}.
  #
  # @param [String] stat stat name
  # @param [Numeric] sample_rate sample rate, 1 for always
  # @yield The operation to be timed
  # @see #timing
  # @example Report the time (in ms) taken to activate an account
  #   $statsd.time('account.activate') { @account.activate! }
  def time(stat, sample_rate=1)
    start = MonotonicTime.time_in_ms
    result = yield
  ensure
    timing(stat, (MonotonicTime.time_in_ms - start).round, sample_rate)
    result
  end

  # Creates and yields a Batch that can be used to batch instrument reports into
  # larger packets. Batches are sent either when the packet is "full" (defined
  # by batch_size), or when the block completes, whichever is the sooner.
  #
  # @yield [Batch] a statsd subclass that collects and batches instruments
  # @example Batch two instument operations:
  #   $statsd.batch do |batch|
  #     batch.increment 'sys.requests'
  #     batch.gauge('user.count', User.count)
  #   end
  def batch(&block)
    Batch.new(self).easy(&block)
  end

  # Reconnects the socket, useful if the address of the statsd has changed. This
  # method is not thread safe from a perspective of stat submission. It is safe
  # from resource leaks. Users do not normally need to call this, but calling it
  # may be appropriate when reconfiguring a process (e.g. from HUP).
  def connect
    @s_mu.synchronize do
      begin
        @socket.close if @socket
      rescue
        # Errors are ignored on reconnects.
      end

      case @protocol
      when :tcp
        @socket = TCPSocket.new @host, @port
      else
        @socket = UDPSocket.new Addrinfo.ip(@host).afamily
        @socket.connect host, port
      end
    end
  end

  protected

  def send_to_socket(message)
    self.class.logger.debug { "Statsd: #{message}" } if self.class.logger

    retries = 0
    n = 0
    while true
      # send(2) is atomic, however, in stream cases (TCP) the socket is left
      # in an inconsistent state if a partial message is written. If that case
      # occurs, the socket is closed down and we retry on a new socket.
      message = @protocol == :tcp ? message + "\n" : message
      n = socket.write(message) rescue (err = $!; 0)
      if n == message.length
        break
      end

      connect
      retries += 1
      raise (err || "statsd: Failed to send after #{retries} attempts") if retries >= 5
    end
    n
  rescue => boom
    self.class.logger.error { "Statsd: #{boom.class} #{boom}" } if self.class.logger
    nil
  end

  private

  def send_stats(stat, delta, type, sample_rate=1)
    if sample_rate == 1 or rand < sample_rate
      # Replace Ruby module scoping with '.' and reserved chars (: | @) with underscores.
      stat = stat.to_s.gsub('::', delimiter).tr(':|@', '_')
      rate = "|@#{sample_rate}" unless sample_rate == 1
      send_to_socket "#{prefix}#{stat}#{postfix}:#{delta}|#{type}#{rate}"
    end
  end

  def socket
    # Subtle: If the socket is half-way through initialization in connect, it
    # cannot be used yet.
    @s_mu.synchronize { @socket } || raise(ThreadError, "socket missing")
  end
end
