module Searchkick
  class IndexCache
    def initialize(max_size: 20)
      @data = {}
      @mutex = Mutex.new
      @max_size = max_size
    end

    # probably a better pattern for this
    # but keep it simple
    def fetch(name)
      # thread-safe in MRI without mutex
      # due to how context switching works
      @mutex.synchronize do
        if @data.key?(name)
          @data[name]
        else
          @data.clear if @data.size >= @max_size
          @data[name] = yield
        end
      end
    end

    def clear
      @mutex.synchronize do
        @data.clear
      end
    end
  end
end
