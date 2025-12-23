require 'mock_redis/undef_redis_methods'

class MockRedis
  class TransactionWrapper
    include UndefRedisMethods

    def respond_to?(method, include_private = false)
      super || @db.respond_to?(method)
    end

    def initialize(db)
      @db = db
      @transaction_futures = []
      @multi_stack = []
      @multi_block_given = false
    end

    ruby2_keywords def method_missing(method, *args, &block)
      if in_multi?
        future = MockRedis::Future.new([method, *args], block)
        @transaction_futures << future

        if @multi_block_given
          future
        else
          'QUEUED'
        end
      else
        @db.expire_keys
        @db.send(method, *args, &block)
      end
    end

    def initialize_copy(source)
      super
      @db = @db.clone
      @transaction_futures = @transaction_futures.clone
      @multi_stack = @multi_stack.clone
    end

    def discard
      unless in_multi?
        raise Redis::CommandError, 'ERR DISCARD without MULTI'
      end
      pop_multi

      @transaction_futures = []
      'OK'
    end

    def exec
      unless in_multi?
        raise Redis::CommandError, 'ERR EXEC without MULTI'
      end
      pop_multi
      return if in_multi?
      @multi_block_given = false

      responses = @transaction_futures.map do |future|
        begin
          result = send(*future.command)
          future.store_result(result)
          future.value
        rescue StandardError => e
          e
        end
      end

      @transaction_futures = []
      responses
    end

    def in_multi?
      @multi_stack.any?
    end

    def push_multi
      @multi_stack.push(@multi_stack.size + 1)
    end

    def pop_multi
      @multi_stack.pop
    end

    def multi
      if block_given?
        push_multi
        @multi_block_given = true
        begin
          yield(self)
          exec
        rescue StandardError => e
          discard
          raise e
        end
      else
        raise Redis::CommandError, 'ERR MULTI calls can not be nested' if in_multi?
        push_multi
        'OK'
      end
    end

    def pipelined
      yield(self) if block_given?
    end

    def unwatch
      'OK'
    end

    def watch(*_)
      if block_given?
        yield self
      else
        'OK'
      end
    end
  end
end
