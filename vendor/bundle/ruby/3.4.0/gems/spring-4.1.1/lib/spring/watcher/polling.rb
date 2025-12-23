require "spring/watcher/abstract"

module Spring
  module Watcher
    class Polling < Abstract
      attr_reader :mtime

      def initialize(root, latency)
        super
        @mtime  = 0
        @poller = nil
      end

      def check_stale
        synchronize do
          computed = compute_mtime
          if mtime < computed
            debug { "check_stale: mtime=#{mtime.inspect} < computed=#{computed.inspect}" }
            mark_stale
          end
        end
      end

      def add(*)
        check_stale if @poller
        super
      end

      def start
        debug { "start: poller=#{@poller.inspect}" }
        unless @poller
          @poller = Thread.new {
            Thread.current.abort_on_exception = true

            begin
              until stale?
                Kernel.sleep latency
                check_stale
              end
            rescue Exception => e
              debug do
                "poller: aborted: #{e.class}: #{e}\n  #{e.backtrace.join("\n  ")}"
              end
              raise
            ensure
              @poller = nil
            end
          }
        end
      end

      def stop
        debug { "stopping poller: #{@poller.inspect}" }
        if @poller
          @poller.kill
          @poller = nil
        end
      end

      def running?
        @poller && @poller.alive?
      end

      def subjects_changed
        computed = compute_mtime
        debug { "subjects_changed: mtime #{@mtime} -> #{computed}" }
        @mtime = computed
      end

      private

      def compute_mtime
        expanded_files.map do |f|
          # Get the mtime of symlink targets. Ignore dangling symlinks.
          if File.symlink?(f)
            begin
              File.mtime(f)
            rescue Errno::ENOENT
              0
            end
          # If a file no longer exists, treat it as changed.
          else
            begin
              File.mtime(f)
            rescue Errno::ENOENT
              debug { "compute_mtime: no longer exists: #{f}" }
              Float::MAX
            end
          end.to_f
        end.max || 0
      end

      def expanded_files
        (files.keys + Dir["{#{directories.keys.map { |d| "#{d}/**/*" }.join(",")}}"]).uniq
      end
    end
  end
end
