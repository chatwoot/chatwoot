# frozen_string_literal: true

require "connection_pool"

class RedisClient
  class Pooled
    EMPTY_HASH = {}.freeze

    include Common

    def initialize(
      config,
      id: config.id,
      connect_timeout: config.connect_timeout,
      read_timeout: config.read_timeout,
      write_timeout: config.write_timeout,
      **kwargs
    )
      super(config, id: id, connect_timeout: connect_timeout, read_timeout: read_timeout, write_timeout: write_timeout)
      @pool_kwargs = kwargs
      @pool = new_pool
      @mutex = Mutex.new
    end

    def with(options = EMPTY_HASH)
      pool.with(options) do |client|
        client.connect_timeout = connect_timeout
        client.read_timeout = read_timeout
        client.write_timeout = write_timeout
        yield client
      end
    rescue ConnectionPool::TimeoutError => error
      raise CheckoutTimeoutError, "Couldn't checkout a connection in time: #{error.message}"
    end
    alias_method :then, :with

    def close
      if @pool
        @mutex.synchronize do
          pool = @pool
          @pool = nil
          pool&.shutdown(&:close)
        end
      end
      nil
    end

    def size
      pool.size
    end

    methods = %w(pipelined multi pubsub call call_v call_once call_once_v blocking_call blocking_call_v)
    iterable_methods = %w(scan sscan hscan zscan)
    methods.each do |method|
      class_eval <<~RUBY, __FILE__, __LINE__ + 1
        def #{method}(*args, &block)
          with { |r| r.#{method}(*args, &block) }
        end
        ruby2_keywords :#{method} if respond_to?(:ruby2_keywords, true)
      RUBY
    end

    iterable_methods.each do |method|
      class_eval <<~RUBY, __FILE__, __LINE__ + 1
        def #{method}(*args, &block)
          unless block_given?
            return to_enum(__callee__, *args)
          end

          with { |r| r.#{method}(*args, &block) }
        end
        ruby2_keywords :#{method} if respond_to?(:ruby2_keywords, true)
      RUBY
    end

    private

    def pool
      @pool ||= @mutex.synchronize { new_pool }
    end

    def new_pool
      ConnectionPool.new(**@pool_kwargs) { @config.new_client }
    end
  end
end
