# frozen_string_literal: true

class RedisClient
  module PIDCache
    if !Process.respond_to?(:fork) # JRuby or TruffleRuby
      @pid = Process.pid
      singleton_class.attr_reader(:pid)
    elsif Process.respond_to?(:_fork) # Ruby 3.1+
      class << self
        attr_reader :pid

        def update!
          @pid = Process.pid
        end
      end
      update!

      module CoreExt
        def _fork
          child_pid = super
          PIDCache.update! if child_pid == 0
          child_pid
        end
      end
      Process.singleton_class.prepend(CoreExt)
    else # Ruby 3.0 or older
      class << self
        def pid
          Process.pid
        end
      end
    end
  end
end
