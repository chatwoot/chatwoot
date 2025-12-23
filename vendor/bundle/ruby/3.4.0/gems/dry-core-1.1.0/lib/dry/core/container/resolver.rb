# frozen_string_literal: true

module Dry
  module Core
    class Container
      # Default resolver for resolving items from container
      #
      # @api public
      class Resolver
        # Resolve an item from the container
        #
        # @param [Concurrent::Hash] container
        #   The container
        # @param [Mixed] key
        #   The key for the item you wish to resolve
        # @yield
        #   Fallback block to call when a key is missing. Its result will be returned
        # @yieldparam [Mixed] key Missing key
        #
        # @raise [KeyError]
        #   If the given key is not registered with the container (and no block provided)
        #
        #
        # @return [Mixed]
        #
        # @api public
        def call(container, key)
          item = container.fetch(key.to_s) do
            if block_given?
              return yield(key)
            else
              raise KeyError.new(%(key not found: "#{key}"), key: key.to_s, receiver: container)
            end
          end

          item.call
        end

        # Check whether an items is registered under the given key
        #
        # @param [Concurrent::Hash] container
        #   The container
        # @param [Mixed] key
        #   The key you wish to check for registration with
        #
        # @return [Bool]
        #
        # @api public
        def key?(container, key)
          container.key?(key.to_s)
        end

        # An array of registered names for the container
        #
        # @return [Array]
        #
        # @api public
        def keys(container)
          container.keys
        end

        # Calls block once for each key in container, passing the key as a parameter.
        #
        # If no block is given, an enumerator is returned instead.
        #
        # @return Hash
        #
        # @api public
        def each_key(container, &)
          container.each_key(&)
        end

        # Calls block once for each key in container, passing the key and
        # the registered item parameters.
        #
        # If no block is given, an enumerator is returned instead.
        #
        # @return Key, Value
        #
        # @api public
        # @note In discussions with other developers, it was felt that being able
        #       to iterate over not just the registered keys, but to see what was
        #       registered would be very helpful. This is a step toward doing that.
        def each(container, &)
          container.map { |key, value| [key, value.call] }.each(&)
        end
      end
    end
  end
end
