# frozen_string_literal: true

module Nokogiri
  module CSS
    module SelectorCache # :nodoc:
      @cache = {}
      @mutex = Mutex.new

      class << self
        # Retrieve the cached XPath expressions for the key
        def [](key)
          @mutex.synchronize { @cache[key] }
        end

        # Insert the XPath expressions `value` at the cache key
        def []=(key, value)
          @mutex.synchronize { @cache[key] = value }
        end

        # Clear the cache
        def clear_cache(create_new_object = false)
          @mutex.synchronize do
            if create_new_object # used in tests to avoid 'method redefined' warnings when injecting spies
              @cache = {}
            else
              @cache.clear
            end
          end
        end

        # Construct a unique key cache key
        def key(selector:, visitor:)
          [selector, visitor.config]
        end
      end
    end
  end
end
