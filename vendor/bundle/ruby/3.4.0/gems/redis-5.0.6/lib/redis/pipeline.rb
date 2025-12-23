# frozen_string_literal: true

require "delegate"

class Redis
  class PipelinedConnection
    attr_accessor :db

    def initialize(pipeline, futures = [])
      @pipeline = pipeline
      @futures = futures
    end

    include Commands

    def pipelined
      yield self
    end

    def multi
      transaction = MultiConnection.new(@pipeline, @futures)
      send_command([:multi])
      size = @futures.size
      yield transaction
      multi_future = MultiFuture.new(@futures[size..-1])
      @pipeline.call_v([:exec]) do |result|
        multi_future._set(result)
      end
      @futures << multi_future
      multi_future
    end

    private

    def synchronize
      yield self
    end

    def send_command(command, &block)
      future = Future.new(command, block)
      @pipeline.call_v(command) do |result|
        future._set(result)
      end
      @futures << future
      future
    end

    def send_blocking_command(command, timeout, &block)
      future = Future.new(command, block)
      @pipeline.blocking_call_v(timeout, command) do |result|
        future._set(result)
      end
      @futures << future
      future
    end
  end

  class MultiConnection < PipelinedConnection
    def multi
      raise Redis::Error, "Can't nest multi transaction"
    end

    private

    # Blocking commands inside transaction behave like non-blocking.
    # It shouldn't be done though.
    # https://redis.io/commands/blpop/#blpop-inside-a-multi--exec-transaction
    def send_blocking_command(command, _timeout, &block)
      send_command(command, &block)
    end
  end

  class FutureNotReady < RuntimeError
    def initialize
      super("Value will be available once the pipeline executes.")
    end
  end

  class Future < BasicObject
    FutureNotReady = ::Redis::FutureNotReady.new

    def initialize(command, coerce)
      @command = command
      @object = FutureNotReady
      @coerce = coerce
    end

    def inspect
      "<Redis::Future #{@command.inspect}>"
    end

    def _set(object)
      @object = @coerce ? @coerce.call(object) : object
      value
    end

    def value
      ::Kernel.raise(@object) if @object.is_a?(::StandardError)
      @object
    end

    def is_a?(other)
      self.class.ancestors.include?(other)
    end

    def class
      Future
    end
  end

  class MultiFuture < Future
    def initialize(futures)
      @futures = futures
      @command = [:exec]
      @object = FutureNotReady
    end

    def _set(replies)
      if replies
        @futures.each_with_index do |future, index|
          future._set(replies[index])
        end
      end
      @object = replies
    end
  end
end
