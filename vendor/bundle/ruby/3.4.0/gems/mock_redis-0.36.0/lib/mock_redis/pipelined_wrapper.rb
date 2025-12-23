class MockRedis
  class PipelinedWrapper
    include UndefRedisMethods

    def respond_to?(method, include_private = false)
      super || @db.respond_to?(method)
    end

    def initialize(db)
      @db = db
      @pipelined_futures = []
      @nesting_level = 0
    end

    def initialize_copy(source)
      super
      @db = @db.clone
      @pipelined_futures = @pipelined_futures.clone
    end

    ruby2_keywords def method_missing(method, *args, &block)
      if in_pipeline?
        future = MockRedis::Future.new([method, *args], block)
        @pipelined_futures << future
        future
      else
        @db.send(method, *args, &block)
      end
    end

    def pipelined(_options = {})
      begin
        @nesting_level += 1
        yield self
      ensure
        @nesting_level -= 1
      end

      if in_pipeline?
        return
      end

      responses = @pipelined_futures.flat_map do |future|
        begin
          result = if future.block
                     send(*future.command, &future.block)
                   else
                     send(*future.command)
                   end
          future.store_result(result)

          if future.block
            result
          else
            [result]
          end
        rescue StandardError => e
          e
        end
      end
      @pipelined_futures = []
      responses
    end

    private

    def in_pipeline?
      @nesting_level > 0
    end
  end
end
