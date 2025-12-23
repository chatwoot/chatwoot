require 'thread'

require 'forwardable'

module SassListen
  module Event
    class Queue
      class Config
        def initialize(relative)
          @relative = relative
        end

        def relative?
          @relative
        end
      end

      def initialize(config, &block)
        @event_queue = ::Queue.new
        @block = block
        @config = config
      end

      def <<(args)
        type, change, dir, path, options = *args
        fail "Invalid type: #{type.inspect}" unless [:dir, :file].include? type
        fail "Invalid change: #{change.inspect}" unless change.is_a?(Symbol)
        fail "Invalid path: #{path.inspect}" unless path.is_a?(String)

        dir = _safe_relative_from_cwd(dir)
        event_queue.public_send(:<<, [type, change, dir, path, options])

        block.call(args) if block
      end

      def empty?
        event_queue.empty?
      end

      def pop
        event_queue.pop
      end

      private

      attr_reader :event_queue
      attr_reader :block
      attr_reader :config

      def _safe_relative_from_cwd(dir)
        return dir unless config.relative?
        dir.relative_path_from(Pathname.pwd)
      rescue ArgumentError
        dir
      end
    end
  end
end
