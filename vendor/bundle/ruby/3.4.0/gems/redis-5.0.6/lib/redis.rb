# frozen_string_literal: true

require "monitor"
require "redis/errors"
require "redis/commands"

class Redis
  BASE_PATH = __dir__
  Deprecated = Class.new(StandardError)

  class << self
    attr_accessor :silence_deprecations, :raise_deprecations

    def deprecate!(message)
      unless silence_deprecations
        if raise_deprecations
          raise Deprecated, message
        else
          ::Kernel.warn(message)
        end
      end
    end
  end

  # soft-deprecated
  # We added this back for older sidekiq releases
  module Connection
    class << self
      def drivers
        [RedisClient.default_driver]
      end
    end
  end

  include Commands

  SERVER_URL_OPTIONS = %i(url host port path).freeze

  # Create a new client instance
  #
  # @param [Hash] options
  # @option options [String] :url (value of the environment variable REDIS_URL) a Redis URL, for a TCP connection:
  #   `redis://:[password]@[hostname]:[port]/[db]` (password, port and database are optional), for a unix socket
  #    connection: `unix://[path to Redis socket]`. This overrides all other options.
  # @option options [String] :host ("127.0.0.1") server hostname
  # @option options [Integer] :port (6379) server port
  # @option options [String] :path path to server socket (overrides host and port)
  # @option options [Float] :timeout (5.0) timeout in seconds
  # @option options [Float] :connect_timeout (same as timeout) timeout for initial connect in seconds
  # @option options [String] :username Username to authenticate against server
  # @option options [String] :password Password to authenticate against server
  # @option options [Integer] :db (0) Database to select after connect and on reconnects
  # @option options [Symbol] :driver Driver to use, currently supported: `:ruby`, `:hiredis`
  # @option options [String] :id ID for the client connection, assigns name to current connection by sending
  #   `CLIENT SETNAME`
  # @option options [Integer, Array<Integer, Float>] :reconnect_attempts Number of attempts trying to connect,
  #   or a list of sleep duration between attempts.
  # @option options [Boolean] :inherit_socket (false) Whether to use socket in forked process or not
  # @option options [String] :name The name of the server group to connect to.
  # @option options [Array] :sentinels List of sentinels to contact
  #
  # @return [Redis] a new client instance
  def initialize(options = {})
    @monitor = Monitor.new
    @options = options.dup
    @options[:reconnect_attempts] = 1 unless @options.key?(:reconnect_attempts)
    if ENV["REDIS_URL"] && SERVER_URL_OPTIONS.none? { |o| @options.key?(o) }
      @options[:url] = ENV["REDIS_URL"]
    end
    inherit_socket = @options.delete(:inherit_socket)
    @subscription_client = nil

    @client = initialize_client(@options)
    @client.inherit_socket! if inherit_socket
  end

  # Run code without the client reconnecting
  def without_reconnect(&block)
    @client.disable_reconnection(&block)
  end

  # Test whether or not the client is connected
  def connected?
    @client.connected? || @subscription_client&.connected?
  end

  # Disconnect the client as quickly and silently as possible.
  def close
    @client.close
    @subscription_client&.close
  end
  alias disconnect! close

  def with
    yield self
  end

  def _client
    @client
  end

  def pipelined
    synchronize do |client|
      client.pipelined do |raw_pipeline|
        yield PipelinedConnection.new(raw_pipeline)
      end
    end
  end

  def id
    @client.id || @client.server_url
  end

  def inspect
    "#<Redis client v#{Redis::VERSION} for #{id}>"
  end

  def dup
    self.class.new(@options)
  end

  def connection
    {
      host: @client.host,
      port: @client.port,
      db: @client.db,
      id: id,
      location: "#{@client.host}:#{@client.port}"
    }
  end

  private

  def initialize_client(options)
    if options.key?(:cluster)
      raise "Redis Cluster support was moved to the `redis-clustering` gem."
    end

    if options.key?(:sentinels)
      if url = options.delete(:url)
        uri = URI.parse(url)
        if !options.key?(:name) && uri.host
          options[:name] = uri.host
        end

        if !options.key?(:password) && uri.password && !uri.password.empty?
          options[:password] = uri.password
        end

        if !options.key?(:username) && uri.user && !uri.user.empty?
          options[:username] = uri.user
        end
      end

      Client.sentinel(**options).new_client
    else
      Client.config(**options).new_client
    end
  end

  def synchronize
    @monitor.synchronize { yield(@client) }
  end

  def send_command(command, &block)
    @monitor.synchronize do
      @client.call_v(command, &block)
    end
  end

  def send_blocking_command(command, timeout, &block)
    @monitor.synchronize do
      @client.blocking_call_v(timeout, command, &block)
    end
  end

  def _subscription(method, timeout, channels, block)
    if block
      if @subscription_client
        raise SubscriptionError, "This client is already subscribed"
      end

      begin
        @subscription_client = SubscribedClient.new(@client.pubsub)
        if timeout > 0
          @subscription_client.send(method, timeout, *channels, &block)
        else
          @subscription_client.send(method, *channels, &block)
        end
      ensure
        @subscription_client = nil
      end
    else
      unless @subscription_client
        raise SubscriptionError, "This client is not subscribed"
      end

      @subscription_client.call_v([method].concat(channels))
    end
  end
end

require "redis/version"
require "redis/client"
require "redis/pipeline"
require "redis/subscribe"
