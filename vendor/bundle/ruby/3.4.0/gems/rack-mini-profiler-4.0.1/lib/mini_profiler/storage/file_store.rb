# frozen_string_literal: true

require 'securerandom'

module Rack
  class MiniProfiler
    class FileStore < AbstractStore

      # Sub-class thread so we have a named thread (useful for debugging in Thread.list).
      class CacheCleanupThread < Thread
      end

      class FileCache
        def initialize(path, prefix)
          @path = path
          @prefix = prefix
        end

        def [](key)
          begin
            data = ::File.open(path(key), "rb") { |f| f.read }
            # rubocop:disable Security/MarshalLoad
            Marshal.load data
            # rubocop:enable Security/MarshalLoad
          rescue
            nil
          end
        end

        def []=(key, val)
          ::File.open(path(key), "wb+") do |f|
            f.sync = true
            f.write Marshal.dump(val)
          end
        end

        private
        if Gem.win_platform?
          def path(key)
            @path.dup << "/" << @prefix << "_" << key.gsub(/:/, '_')
          end
        else
          def path(key)
            @path.dup << "/" << @prefix << "_" << key
          end
        end
      end

      EXPIRES_IN_SECONDS = 60 * 60 * 24

      def initialize(args = nil)
        args ||= {}
        @path = args[:path]
        @expires_in_seconds = args[:expires_in] || EXPIRES_IN_SECONDS
        raise ArgumentError.new :path unless @path
        FileUtils.mkdir_p(@path) unless ::File.exist?(@path)

        @timer_struct_cache = FileCache.new(@path, "mp_timers")
        @timer_struct_lock  = Mutex.new
        @user_view_cache    = FileCache.new(@path, "mp_views")
        @user_view_lock     = Mutex.new

        @auth_token_cache    = FileCache.new(@path, "tokens")
        @auth_token_lock     = Mutex.new

        me = self
        t = CacheCleanupThread.new do
          interval = 10
          cleanup_cache_cycle = 3600
          cycle_count = 1

          begin
            until Thread.current[:should_exit] do
              # TODO: a sane retry count before bailing

              # We don't want to hit the filesystem every 10s to clean up the cache so we need to do a bit of
              # accounting to avoid sleeping that entire time.  We don't want to sleep for the entire period because
              # it means the thread will stay live in hot deployment scenarios, keeping a potentially large memory
              # graph from being garbage collected upon undeploy.
              if cycle_count * interval >= cleanup_cache_cycle
                cycle_count = 1
                me.cleanup_cache
              end

              sleep(interval)
              cycle_count += 1
            end
          rescue
            # don't crash the thread, we can clean up next time
          end
        end

        at_exit { t[:should_exit] = true }
      end

      def save(page_struct)
        @timer_struct_lock.synchronize {
          @timer_struct_cache[page_struct[:id]] = page_struct
        }
      end

      def load(id)
        @timer_struct_lock.synchronize {
          @timer_struct_cache[id]
        }
      end

      def set_unviewed(user, id)
        @user_view_lock.synchronize {
          current = @user_view_cache[user]
          current = [] unless Array === current
          current << id
          @user_view_cache[user] = current.uniq
        }
      end

      def set_viewed(user, id)
        @user_view_lock.synchronize {
          @user_view_cache[user] ||= []
          current = @user_view_cache[user]
          current = [] unless Array === current
          current.delete(id)
          @user_view_cache[user] = current.uniq
        }
      end

      def set_all_unviewed(user, ids)
        @user_view_lock.synchronize {
          @user_view_cache[user] = ids.uniq
        }
      end

      def get_unviewed_ids(user)
        @user_view_lock.synchronize {
          @user_view_cache[user]
        }
      end

      def flush_tokens
        @auth_token_lock.synchronize {
          @auth_token_cache[""] = nil
        }
      end

      def allowed_tokens
        @auth_token_lock.synchronize {
          token1, token2, cycle_at = @auth_token_cache[""]

          unless cycle_at && (Float === cycle_at) && (cycle_at > Process.clock_gettime(Process::CLOCK_MONOTONIC))
            token2 = token1
            token1 = SecureRandom.hex
            cycle_at = Process.clock_gettime(Process::CLOCK_MONOTONIC) + Rack::MiniProfiler::AbstractStore::MAX_TOKEN_AGE
          end

          @auth_token_cache[""] = [token1, token2, cycle_at]

          [token1, token2].compact
        }
      end

      def cleanup_cache
        files = Dir.entries(@path)
        @timer_struct_lock.synchronize {
          files.each do |f|
            f = @path + '/' + f
            ::File.delete f if ::File.basename(f) =~ (/^mp_timers/) && ((Time.now - ::File.mtime(f)) > @expires_in_seconds)
          end
        }
        @user_view_lock.synchronize {
          files.each do |f|
            f = @path + '/' + f
            ::File.delete f if ::File.basename(f) =~ (/^mp_views/) && ((Time.now - ::File.mtime(f)) > @expires_in_seconds)
          end
        }
      end

    end
  end
end
