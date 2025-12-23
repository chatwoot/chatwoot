# frozen_string_literal: true

module Dry
  module Types
    # Common API for building type objects in a convenient way
    #
    #
    # @api public
    module BuilderMethods
      # @api private
      def included(base)
        super
        base.extend(BuilderMethods)
      end

      # Build an array type.
      #
      # Shortcut for Array#of.
      #
      # @example
      #   Types::Strings = Types.Array(Types::String)
      #
      # @param [Dry::Types::Type] type
      #
      # @return [Dry::Types::Array]
      def Array(type) = Strict(::Array).of(type)

      # Build a hash schema
      #
      # @param [Hash{Symbol => Dry::Types::Type}] type_map
      #
      # @return [Dry::Types::Array]
      def Hash(type_map) = Strict(::Hash).schema(type_map)

      # Build a type which values are instances of a given class
      # Values are checked using `is_a?` call
      #
      # @example
      #   Types::Error = Types.Instance(StandardError)
      #   Types::Error = Types.Strict(StandardError)
      #   Types.Strict(Integer) == Types::Strict::Int # => true
      #
      # @param [Class,Module] klass Class or module
      #
      # @return [Dry::Types::Type]
      def Instance(klass)
        unless klass.is_a?(::Module)
          raise ::ArgumentError, "Expected a class or module, got #{klass.inspect}"
        end

        Nominal(klass).constrained(type: klass)
      end

      alias_method :Strict, :Instance

      # Build a type with a single value
      # The equality check done with `eql?`
      #
      # @param [Object] value
      #
      # @return [Dry::Types::Type]
      def Value(value) = Nominal(value.class).constrained(eql: value)

      # Build a type with a single value
      # The equality check done with `equal?`
      #
      # @param [Object] object
      #
      # @return [Dry::Types::Type]
      def Constant(object) = Nominal(object.class).constrained(is: object)

      # Build a constructor type
      # If no constructor block given it uses .new method
      #
      # @param [Class] klass
      # @param [#call,nil] cons Value constructor
      # @param [#call,nil] block Value constructor
      #
      # @return [Dry::Types::Type]
      def Constructor(klass, cons = nil, &block) # rubocop:disable Metrics/PerceivedComplexity:
        if klass.is_a?(Type)
          if cons || block
            klass.constructor(cons || block)
          else
            klass
          end
        else
          Nominal(klass).constructor(cons || block || klass.method(:new))
        end
      end

      # Build a nominal type
      #
      # @param [Class] klass
      #
      # @return [Dry::Types::Type]
      def Nominal(klass)
        if klass <= ::Array
          Array.new(klass)
        elsif klass <= ::Hash
          Hash.new(klass)
        else
          Nominal.new(klass)
        end
      end

      # Build a map type
      #
      # @example
      #   Types::IntMap = Types.Map(Types::Strict::Integer, 'any')
      #   Types::IntStringMap = Types.Map(Types::Strict::Integer, Types::Strict::String)
      #
      # @param [Type] key_type Key type
      # @param [Type] value_type Value type
      #
      # @return [Dry::Types::Map]
      def Map(key_type, value_type)
        Nominal(::Hash).map(key_type, value_type)
      end

      # Builds a constrained nominal type accepting any value that
      # responds to given methods
      #
      # @example
      #   Types::Callable = Types.Interface(:call)
      #   Types::Contact = Types.Interface(:name, :address)
      #
      # @param methods [Array<String, Symbol>] Method names
      #
      # @return [Dry::Types::Contrained]
      def Interface(*methods)
        methods.reduce(Types["nominal.any"]) do |type, method|
          type.constrained(respond_to: method)
        end
      end
    end
  end
end
