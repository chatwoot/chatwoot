class MockRedis
  class FutureNotReady < RuntimeError; end

  class Future
    attr_reader :command, :block

    def initialize(command, block = nil)
      @command = command
      @block = block
      @result_set = false
    end

    def value
      raise FutureNotReady unless @result_set
      @result
    end

    def store_result(result)
      @result_set = true
      @result = @block ? @block.call(result) : result
    end
  end
end
