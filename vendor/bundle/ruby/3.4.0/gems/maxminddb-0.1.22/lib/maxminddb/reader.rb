
require 'thread'

module MaxMindDB
  class LowMemoryReader
    METADATA_MAX_SIZE = 128 * 1024

    def initialize(path)
      @mutex = Mutex.new
      @file = File.open(path, 'rb')
    end

    def [](pos, length=1)
      atomic_read(length, pos)
    end

    def rindex(search)
      base = [0, @file.size - METADATA_MAX_SIZE].max
      tail = atomic_read(METADATA_MAX_SIZE, base)
      pos = tail.rindex(search)
      return nil if pos.nil?
      base + pos
    end

    def atomic_read(length, pos)
      # Prefer `pread` in environments where it is available. `pread` provides
      # atomic file access across processes.
      if @file.respond_to?(:pread)
        @file.pread(length, pos)
      else
        @mutex.synchronize do
          @file.seek(pos)
          @file.read(length)
        end
      end
    end
  end
end
