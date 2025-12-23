# frozen_string_literal: true

module Dry
  module Core
    class Container
      class Item
        # Factory for create an Item to register inside of container
        #
        # @api public
        class Factory
          # Creates an Item Memoizable or Callable
          # @param [Mixed] item
          # @param [Hash] options
          #
          # @raise [Dry::Core::Container::Error]
          #
          # @return [Dry::Core::Container::Item::Base]
          def call(item, options = {})
            if options[:memoize]
              Item::Memoizable.new(item, options)
            else
              Item::Callable.new(item, options)
            end
          end
        end
      end
    end
  end
end
