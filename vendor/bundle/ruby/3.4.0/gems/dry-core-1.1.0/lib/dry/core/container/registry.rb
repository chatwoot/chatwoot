# frozen_string_literal: true

module Dry
  module Core
    class Container
      # Default registry for registering items with the container
      #
      # @api public
      class Registry
        # @private
        def initialize
          @_mutex = ::Mutex.new
        end

        # Register an item with the container to be resolved later
        #
        # @param [Concurrent::Hash] container
        #   The container
        # @param [Mixed] key
        #   The key to register the container item with (used to resolve)
        # @param [Mixed] item
        #   The item to register with the container
        # @param [Hash] options
        # @option options [Symbol] :call
        #   Whether the item should be called when resolved
        #
        # @raise [Dry::Core::Container::KeyError]
        #   If an item is already registered with the given key
        #
        # @return [Mixed]
        #
        # @api public
        def call(container, key, item, options)
          key = key.to_s.dup.freeze

          @_mutex.synchronize do
            if container.key?(key)
              raise KeyError, "There is already an item registered with the key #{key.inspect}"
            end

            container[key] = factory.call(item, options)
          end
        end

        # @api private
        def factory
          @factory ||= Container::Item::Factory.new
        end
      end
    end
  end
end
