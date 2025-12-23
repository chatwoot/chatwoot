# frozen_string_literal: true

module Dry
  module Core
    class Container
      # @api public
      class Config
        DEFAULT_NAMESPACE_SEPARATOR = "."
        DEFAULT_RESOLVER = Resolver.new
        DEFAULT_REGISTRY = Registry.new

        # @api public
        attr_accessor :namespace_separator

        # @api public
        attr_accessor :resolver

        # @api public
        attr_accessor :registry

        # @api private
        def initialize(
          namespace_separator: DEFAULT_NAMESPACE_SEPARATOR,
          resolver: DEFAULT_RESOLVER,
          registry: DEFAULT_REGISTRY
        )
          @namespace_separator = namespace_separator
          @resolver = resolver
          @registry = registry
        end
      end
    end
  end
end
