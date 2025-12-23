# frozen_string_literal: true

require "concurrent/array"

module Dry
  module Core
    # An implementation of descendants tracker, heavily inspired
    # by the descendants_tracker gem.
    #
    # @example
    #
    #   class Base
    #     extend Dry::Core::DescendantsTracker
    #   end
    #
    #   class A < Base
    #   end
    #
    #   class B < Base
    #   end
    #
    #   class C < A
    #   end
    #
    #   Base.descendants # => [C, B, A]
    #   A.descendants # => [C]
    #   B.descendants # => []
    #
    module DescendantsTracker
      class << self
        # @api private
        def setup(target)
          target.instance_variable_set(:@descendants, ::Concurrent::Array.new)
        end

        private

        # @api private
        def extended(base)
          super

          DescendantsTracker.setup(base)
        end
      end

      # Return the descendants of this class
      #
      # @example
      #   descendants = Parent.descendants
      #
      # @return [Array<Class>]
      #
      # @api public
      attr_reader :descendants

      protected

      # @api private
      def add_descendant(descendant)
        ancestor = superclass
        if ancestor.respond_to?(:add_descendant, true)
          ancestor.add_descendant(descendant)
        end
        descendants.unshift(descendant)
      end

      private

      # @api private
      def inherited(descendant)
        super

        DescendantsTracker.setup(descendant)
        add_descendant(descendant)
      end
    end
  end
end
