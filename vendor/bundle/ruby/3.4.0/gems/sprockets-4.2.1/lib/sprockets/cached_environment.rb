# frozen_string_literal: true
require 'sprockets/base'

module Sprockets
  # `CachedEnvironment` is a special cached version of `Environment`.
  #
  # The exception is that all of its file system methods are cached
  # for the instances lifetime. This makes `CachedEnvironment` much faster. This
  # behavior is ideal in production environments where the file system
  # is immutable.
  #
  # `CachedEnvironment` should not be initialized directly. Instead use
  # `Environment#cached`.
  class CachedEnvironment < Base
    def initialize(environment)
      initialize_configuration(environment)

      @cache   = environment.cache
      @stats   = Concurrent::Map.new
      @entries = Concurrent::Map.new
      @uris    = Concurrent::Map.new
      @processor_cache_keys = Concurrent::Map.new
      @resolved_dependencies = Concurrent::Map.new
    end

    # No-op return self as cached environment.
    def cached
      self
    end
    alias_method :index, :cached

    # Internal: Cache Environment#entries
    def entries(path)
      @entries.fetch_or_store(path) { super(path) }
    end

    # Internal: Cache Environment#stat
    def stat(path)
      @stats.fetch_or_store(path) { super(path) }
    end

    # Internal: Cache Environment#load
    def load(uri)
      @uris.fetch_or_store(uri) { super(uri) }
    end

    # Internal: Cache Environment#processor_cache_key
    def processor_cache_key(str)
      @processor_cache_keys.fetch_or_store(str) { super(str) }
    end

    # Internal: Cache Environment#resolve_dependency
    def resolve_dependency(str)
      @resolved_dependencies.fetch_or_store(str) { super(str) }
    end

    private
      # Cache is immutable, any methods that try to change the runtime config
      # should bomb.
      def config=(config)
        raise RuntimeError, "can't modify immutable cached environment"
      end
  end
end
