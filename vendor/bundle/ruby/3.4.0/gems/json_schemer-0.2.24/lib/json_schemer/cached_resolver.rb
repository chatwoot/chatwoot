# frozen_string_literal: true
module JSONSchemer
  class CachedResolver
    def initialize(&resolver)
      @resolver = resolver
      @cache = {}
    end

    def call(*args)
      @cache[args] = @resolver.call(*args) unless @cache.key?(args)
      @cache[args]
    end
  end

  class CachedRefResolver < CachedResolver; end
end
