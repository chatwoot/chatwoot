module Sass
  module CacheStores
    # A meta-cache that chains multiple caches together.
    # Specifically:
    #
    # * All `#store`s are passed to all caches.
    # * `#retrieve`s are passed to each cache until one has a hit.
    # * When one cache has a hit, the value is `#store`d in all earlier caches.
    class Chain < Base
      # Create a new cache chaining the given caches.
      #
      # @param caches [Array<Sass::CacheStores::Base>] The caches to chain.
      def initialize(*caches)
        @caches = caches
      end

      # @see Base#store
      def store(key, sha, obj)
        @caches.each {|c| c.store(key, sha, obj)}
      end

      # @see Base#retrieve
      def retrieve(key, sha)
        @caches.each_with_index do |c, i|
          obj = c.retrieve(key, sha)
          next unless obj
          @caches[0...i].each {|prev| prev.store(key, sha, obj)}
          return obj
        end
        nil
      end
    end
  end
end
