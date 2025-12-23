# frozen_string_literal: true

require "delegate"

module Dry
  module Core
    class Container
      # @api private
      class NamespaceDSL < ::SimpleDelegator
        # DSL for defining namespaces
        #
        # @param [Dry::Core::Container::Mixin] container
        #   The container
        # @param [String] namespace
        #   The namespace (name)
        # @param [String] namespace_separator
        #   The namespace separator
        # @yield
        #   The block to evaluate to define the namespace
        #
        # @return [Mixed]
        #
        # @api private
        def initialize(container, namespace, namespace_separator, &block)
          @namespace = namespace
          @namespace_separator = namespace_separator

          super(container)

          if block.arity.zero?
            instance_eval(&block)
          else
            yield self
          end
        end

        def register(key, ...)
          super(namespaced(key), ...)
        end

        def namespace(namespace, &)
          super(namespaced(namespace), &)
        end

        def import(namespace)
          namespace(namespace.name, &namespace.block)

          self
        end

        def resolve(key)
          super(namespaced(key))
        end

        private

        def namespaced(key)
          [@namespace, key].join(@namespace_separator)
        end
      end
    end
  end
end
