return if ENV['DISABLE_SPRING_WATCHER_LISTEN']

require "spring/watcher"
require "spring/watcher/abstract"

require "listen"
require "listen/version"

if defined?(Celluloid)
  # fork() doesn't preserve threads, so a clean
  # Celluloid shutdown isn't possible, but we can
  # reduce the 10 second timeout

  # There's a patch for Celluloid to avoid this (search for 'fork' in Celluloid
  # issues)
  Celluloid.shutdown_timeout = 2
end

module Spring
  module Watcher
    class Listen < Abstract
      Spring.watch_method = self

      attr_reader :listener

      def initialize(*)
        super
        @listener = nil
      end

      def start
        return if @listener

        @listener = ::Listen.to(*base_directories, latency: latency, &method(:changed))
        @listener.start
      end

      def stop
        if @listener
          @listener.stop
          @listener = nil
        end
      end

      def running?
        @listener && @listener.processing?
      end

      def subjects_changed
        return unless @listener
        return unless @listener.respond_to?(:directories)
        return unless @listener.directories.sort != base_directories.sort
        restart
      end

      def watching?(file)
        files.include?(file) || file.start_with?(*directories.keys)
      end

      def changed(modified, added, removed)
        synchronize do
          if (modified + added + removed).any? { |f| watching? f }
            mark_stale
          end
        end
      end

      def mark_stale
        super

        # May be called from listen thread which won't be happy
        # about stopping itself, so stop from another thread.
        Thread.new { stop }.join
      end

      def base_directories
        ([root] +
          files.keys.reject       { |f| f.start_with? "#{root}/" }.map { |f| File.expand_path("#{f}/..") } +
          directories.keys.reject { |d| d.start_with? "#{root}/" }
        ).uniq.map { |path| Pathname.new(path) }
      end
    end
  end
end
