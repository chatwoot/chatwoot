# frozen_string_literal: true

module RSpec
  module Support
    # Allows a thread to lock out other threads from a critical section of code,
    # while allowing the thread with the lock to reenter that section.
    #
    # Based on Monitor as of 2.2 -
    # https://github.com/ruby/ruby/blob/eb7ddaa3a47bf48045d26c72eb0f263a53524ebc/lib/monitor.rb#L9
    #
    # Depends on Mutex, but Mutex is only available as part of core since 1.9.1:
    #   exists - http://ruby-doc.org/core-1.9.1/Mutex.html
    #   dne    - http://ruby-doc.org/core-1.9.0/Mutex.html
    #
    # @private
    class ReentrantMutex
      def initialize
        @owner = nil
        @count = 0
        @mutex = Mutex.new
      end

      def synchronize
        enter
        yield
      ensure
        exit
      end

    private

      # This is fixing a bug #501 that is specific to Ruby 3.0. The new implementation
      # depends on `owned?` that was introduced in Ruby 2.0, so both should work for Ruby 2.x.
      if RUBY_VERSION.to_f >= 3.0
        def enter
          @mutex.lock unless @mutex.owned?
          @count += 1
        end

        def exit
          unless @mutex.owned?
            raise ThreadError, "Attempt to unlock a mutex which is locked by another thread/fiber"
          end
          @count -= 1
          @mutex.unlock if @count == 0
        end
      else
        def enter
          @mutex.lock if @owner != Thread.current
          @owner = Thread.current
          @count += 1
        end

        def exit
          @count -= 1
          return unless @count == 0
          @owner = nil
          @mutex.unlock
        end
      end
    end

    if defined? ::Mutex
      # On 1.9 and up, this is in core, so we just use the real one
      class Mutex < ::Mutex
        # If you mock Mutex.new you break our usage of Mutex, so
        # instead we capture the original method to return Mutexes.
        NEW_MUTEX_METHOD = Mutex.method(:new)

        def self.new
          NEW_MUTEX_METHOD.call
        end
      end
    else # For 1.8.7
      # :nocov:
      RSpec::Support.require_rspec_support "mutex"
      # :nocov:
    end
  end
end
