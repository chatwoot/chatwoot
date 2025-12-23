module Sass
  module CacheStores
    # Doesn't store anything, but records what things it should have stored.
    # This doesn't currently have any use except for testing and debugging.
    #
    # @private
    class Null < Base
      def initialize
        @keys = {}
      end

      def _retrieve(key, version, sha)
        nil
      end

      def _store(key, version, sha, contents)
        @keys[key] = true
      end

      def was_set?(key)
        @keys[key]
      end
    end
  end
end
