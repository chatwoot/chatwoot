require "pathname"
require "mutex_m"

module Spring
  module Watcher
    # A user of a watcher can use IO.select to wait for changes:
    #
    #   watcher = MyWatcher.new(root, latency)
    #   IO.select([watcher]) # watcher is running in background
    #   watcher.stale? # => true
    class Abstract
      include Mutex_m

      attr_reader :files, :directories, :root, :latency

      def initialize(root, latency)
        super()

        @root        = File.realpath(root)
        @latency     = latency
        @files       = {}
        @directories = {}
        @stale       = false
        @listeners   = []

        @on_debug    = nil
      end

      def on_debug(&block)
        @on_debug = block
      end

      def debug
        @on_debug.call(yield) if @on_debug
      end

      def add(*items)
        debug { "watcher: add: #{items.inspect}" }

        items = items.flatten.map do |item|
          item = Pathname.new(item)

          if item.relative?
            Pathname.new("#{root}/#{item}")
          else
            item
          end
        end

        items = items.select do |item|
          if item.symlink?
            item.readlink.exist?.tap do |exists|
              if !exists
                debug { "add: ignoring dangling symlink: #{item.inspect} -> #{item.readlink.inspect}" }
              end
            end
          else
            item.exist?
          end
        end

        synchronize {
          items.each do |item|
            if item.directory?
              directories[item.realpath.to_s] = true
            else
              begin
                files[item.realpath.to_s] = true
              rescue Errno::ENOENT
                # Race condition. Ignore symlinks whose target was removed
                # since the check above, or are deeply chained.
                debug { "add: ignoring now-dangling symlink: #{item.inspect} -> #{item.readlink.inspect}" }
              end
            end
          end

          subjects_changed
        }
      end

      def stale?
        @stale
      end

      def on_stale(&block)
        debug { "added listener: #{block.inspect}" }
        @listeners << block
      end

      def mark_stale
        return if stale?
        @stale = true
        debug { "marked stale, calling listeners: listeners=#{@listeners.inspect}" }
        @listeners.each(&:call)
      end

      def restart
        debug { "restarting" }
        stop
        start
      end

      def start
        raise NotImplementedError
      end

      def stop
        raise NotImplementedError
      end

      def subjects_changed
        raise NotImplementedError
      end
    end
  end
end
