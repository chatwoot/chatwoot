# frozen_string_literal: true

require "set"

module Dry
  module Core
    # A list of constants you can use to avoid memory allocations or identity checks.
    #
    # @example Just include this module to your class or module
    #   class Foo
    #     include Dry::Core::Constants
    #     def call(value = EMPTY_ARRAY)
    #        value.map(&:to_s)
    #     end
    #   end
    #
    # @api public
    module Constants
      # An empty array
      EMPTY_ARRAY = [].freeze
      # An empty hash
      EMPTY_HASH = {}.freeze
      # An empty list of options
      EMPTY_OPTS = {}.freeze
      # An empty set
      EMPTY_SET = ::Set.new.freeze
      # An empty string
      EMPTY_STRING = ""
      # Identity function
      IDENTITY = ->(x) { x }.freeze

      # A special value you can use as a default to know if no arguments
      # were passed to the method
      #
      # @example
      #   def method(value = Undefined)
      #     if Undefined.equal?(value)
      #       puts 'no args'
      #     else
      #       puts value
      #     end
      #   end
      Undefined = ::Object.new.tap do |undefined|
        # @api private
        Self = -> { Undefined } # rubocop:disable Lint/ConstantDefinitionInBlock

        # @api public
        def undefined.to_s
          "Undefined"
        end

        # @api public
        def undefined.inspect
          "Undefined"
        end

        # Pick a value, if the first argument is not Undefined, return it back,
        # otherwise return the second arg or yield the block.
        #
        # @example
        #   def method(val = Undefined)
        #     1 + Undefined.default(val, 2)
        #   end
        #
        def undefined.default(x, y = self)
          if equal?(x)
            if equal?(y)
              yield
            else
              y
            end
          else
            x
          end
        end

        # Map a non-undefined value
        #
        # @example
        #   def add_five(val = Undefined)
        #     Undefined.map(val) { |x| x + 5 }
        #   end
        #
        def undefined.map(value)
          if equal?(value)
            self
          else
            yield(value)
          end
        end

        # @api public
        def undefined.dup
          self
        end

        # @api public
        def undefined.clone
          self
        end

        # @api public
        def undefined.coalesce(*args)
          args.find(Self) { |x| !equal?(x) }
        end
      end.freeze

      def self.included(base)
        super

        constants.each do |const_name|
          base.const_set(const_name, const_get(const_name))
        end
      end
    end
  end
end
