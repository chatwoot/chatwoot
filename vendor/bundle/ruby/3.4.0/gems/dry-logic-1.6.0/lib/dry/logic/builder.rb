# frozen_string_literal: true

require "singleton"
require "delegate"

module Dry
  module Logic
    module Builder
      IGNORED_OPERATIONS = %i[
        Abstract
        Binary
        Unary
      ].freeze

      IGNORED_PREDICATES = [
        :predicate
      ].freeze

      # Predicate and operation builder
      #
      # @block [Proc]
      # @return [Builder::Result]
      # @example Check if input is zero
      #   is_zero = Dry::Logic::Builder.call do
      #     negation { lt?(0) ^ gt?(0) }
      #   end
      #
      #   p is_zero.call(1) # => false
      #   p is_zero.call(0) # => true
      #   p is_zero.call(-1) # => false
      def call(&)
        Context.instance.call(&)
      end
      module_function :call
      alias_method :build, :call
      public :call, :build

      class Context
        include Dry::Logic
        include Singleton

        module Predicates
          include Logic::Predicates
        end

        # @see Builder#call
        def call(&)
          instance_eval(&)
        end

        # Defines custom predicate
        #
        # @name [Symbol] Name of predicate
        # @Context [Proc]
        def predicate(name, context = nil, &block)
          if singleton_class.method_defined?(name)
            singleton_class.undef_method(name)
          end

          predicate = Rule::Predicate.new(context || block)

          define_singleton_method(name) do |*args|
            predicate.curry(*args)
          end
        end

        # Defines methods for operations and predicates
        def initialize
          Operations.constants(false).each do |name|
            next if IGNORED_OPERATIONS.include?(name)

            operation = Operations.const_get(name)

            define_singleton_method(name.downcase) do |*args, **kwargs, &block|
              operation.new(*call(&block), *args, **kwargs)
            end
          end

          Predicates::Methods.instance_methods(false).each do |name|
            unless IGNORED_PREDICATES.include?(name)
              predicate(name, Predicates[name])
            end
          end
        end
      end
    end
  end
end
