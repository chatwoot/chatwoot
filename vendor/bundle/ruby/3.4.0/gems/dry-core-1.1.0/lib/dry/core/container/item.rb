# frozen_string_literal: true

module Dry
  module Core
    class Container
      # Base class to abstract Memoizable and Callable implementations
      #
      # @api abstract
      #
      class Item
        NO_OPTIONS = {}.freeze

        # @return [Mixed] the item to be solved later
        attr_reader :item

        # @return [Hash] the options to memoize, call or no.
        attr_reader :options

        # @api abstract
        def initialize(item, options = NO_OPTIONS)
          @item = item
          @options = {
            call: item.is_a?(::Proc) && item.parameters.empty?,
            **options
          }
        end

        # @api abstract
        def call
          raise ::NotImplementedError
        end

        # @private
        def value?
          !callable?
        end

        # @private
        def callable?
          options[:call]
        end

        # Build a new item with transformation applied
        #
        # @private
        def map(func)
          if callable?
            self.class.new(-> { func.(item.call) }, options)
          else
            self.class.new(func.(item), options)
          end
        end
      end
    end
  end
end
