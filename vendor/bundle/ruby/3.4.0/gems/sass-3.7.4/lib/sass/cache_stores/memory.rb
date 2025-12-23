module Sass
  module CacheStores
    # A backend for the Sass cache using in-process memory.
    class Memory < Base
      # Since the {Memory} store is stored in the Sass tree's options hash,
      # when the options get serialized as part of serializing the tree,
      # you get crazy exponential growth in the size of the cached objects
      # unless you don't dump the cache.
      #
      # @private
      def _dump(depth)
        ""
      end

      # If we deserialize this class, just make a new empty one.
      #
      # @private
      def self._load(repr)
        Memory.new
      end

      # Create a new, empty cache store.
      def initialize
        @contents = {}
      end

      # @see Base#retrieve
      def retrieve(key, sha)
        return unless @contents.has_key?(key)
        return unless @contents[key][:sha] == sha
        obj = @contents[key][:obj]
        obj.respond_to?(:deep_copy) ? obj.deep_copy : obj.dup
      end

      # @see Base#store
      def store(key, sha, obj)
        @contents[key] = {:sha => sha, :obj => obj}
      end

      # Destructively clear the cache.
      def reset!
        @contents = {}
      end
    end
  end
end
