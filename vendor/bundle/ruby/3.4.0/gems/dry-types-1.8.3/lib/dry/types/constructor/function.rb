# frozen_string_literal: true

require "concurrent/map"

module Dry
  module Types
    class Constructor < Nominal
      # Function is used internally by Constructor types
      #
      # @api private
      class Function
        # Wrapper for unsafe coercion functions
        #
        # @api private
        class Safe < Function
          def call(input, &)
            @fn.(input)
          rescue ::NoMethodError, ::TypeError, ::ArgumentError => e
            CoercionError.handle(e, &)
          end
        end

        # Coercion via a method call on a known object
        #
        # @api private
        class MethodCall < Function
          @cache = ::Concurrent::Map.new

          # Choose or build the base class
          #
          # @return [Function]
          def self.call_class(method, public, safe)
            @cache.fetch_or_store([method, public, safe]) do
              if public
                ::Class.new(PublicCall) do
                  include PublicCall.call_interface(method, safe)

                  define_method(:__to_s__) do
                    "#<PublicCall for :#{method}>"
                  end
                end
              elsif safe
                PrivateCall
              else
                PrivateSafeCall
              end
            end
          end

          # Coercion with a publicly accessible method call
          #
          # @api private
          class PublicCall < MethodCall
            @interfaces = ::Concurrent::Map.new

            # Choose or build the interface
            #
            # @return [::Module]
            def self.call_interface(method, safe)
              @interfaces.fetch_or_store([method, safe]) do
                ::Module.new do
                  if safe
                    module_eval(<<~RUBY, __FILE__, __LINE__ + 1)
                      def call(input, &)             # def call(input, &)
                        @target.#{method}(input, &)  #   @target.coerce(input, &)
                      end                            # end
                    RUBY
                  else
                    module_eval(<<~RUBY, __FILE__, __LINE__ + 1)
                      def call(input, &)                                             # def call(input, &)
                        @target.#{method}(input)                                     #   @target.coerce(input)
                      rescue ::NoMethodError, ::TypeError, ::ArgumentError => error  # rescue ::NoMethodError, ::TypeError, ::ArgumentError => error
                        CoercionError.handle(error, &)                               #   CoercionError.handle(error, &)
                      end                                                            # end
                    RUBY
                  end
                end
              end
            end
          end

          # Coercion via a private method call
          #
          # @api private
          class PrivateCall < MethodCall
            def call(input, &) = @target.send(@name, input, &)
          end

          # Coercion via an unsafe private method call
          #
          # @api private
          class PrivateSafeCall < PrivateCall
            def call(input, &)
              @target.send(@name, input)
            rescue ::NoMethodError, ::TypeError, ::ArgumentError => e
              CoercionError.handle(e, &)
            end
          end

          # @api private
          #
          # @return [MethodCall]
          def self.[](fn, safe)
            public = fn.receiver.respond_to?(fn.name)
            MethodCall.call_class(fn.name, public, safe).new(fn)
          end

          attr_reader :target, :name

          def initialize(fn)
            super
            @target = fn.receiver
            @name = fn.name
          end

          def to_ast = [:method, target, name]
        end

        class Wrapper < Function
          # @return [Object]
          def call(input, type, &)
            @fn.(input, type, &)
          rescue ::NoMethodError, ::TypeError, ::ArgumentError => e
            CoercionError.handle(e, &)
          end
          alias_method :[], :call

          def arity = 2
        end

        # Choose or build specialized invokation code for a callable
        #
        # @param [#call] fn
        # @return [Function]
        def self.[](fn)
          raise ::ArgumentError, "Missing constructor block" if fn.nil?

          if fn.is_a?(Function)
            fn
          elsif fn.respond_to?(:arity) && fn.arity.equal?(2)
            Wrapper.new(fn)
          elsif fn.is_a?(::Method)
            MethodCall[fn, yields_block?(fn)]
          elsif yields_block?(fn)
            new(fn)
          else
            Safe.new(fn)
          end
        end

        # @return [Boolean]
        def self.yields_block?(fn)
          *, (last_arg,) =
            if fn.respond_to?(:parameters)
              fn.parameters
            else
              fn.method(:call).parameters
            end

          last_arg.equal?(:block)
        end

        include ::Dry::Equalizer(:fn, immutable: true)

        attr_reader :fn

        def initialize(fn)
          @fn = fn
        end

        # @return [Object]
        def call(input, &) = @fn.(input, &)
        alias_method :[], :call

        # @return [Integer]
        def arity = 1

        def wrapper? = arity.equal?(2)

        # @return [Array]
        def to_ast
          if fn.is_a?(::Proc)
            [:id, FnContainer.register(fn)]
          else
            [:callable, fn]
          end
        end

        # @return [Function]
        def >>(other)
          f = Function[other]
          Function[-> x, &b { f.(self.(x, &b), &b) }]
        end

        # @return [Function]
        def <<(other)
          f = Function[other]
          Function[-> x, &b { self.(f.(x, &b), &b) }]
        end
      end
    end
  end
end
