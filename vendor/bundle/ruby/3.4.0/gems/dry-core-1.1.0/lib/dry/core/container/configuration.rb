# frozen_string_literal: true

module Dry
  module Core
    class Container
      # @api public
      module Configuration
        # Use dry/configurable if it's available
        begin
          require "dry/configurable"

          # @api private
          def self.extended(klass)
            super
            klass.class_eval do
              extend Dry::Configurable

              setting :namespace_separator, default: Config::DEFAULT_NAMESPACE_SEPARATOR
              setting :resolver, default: Config::DEFAULT_RESOLVER
              setting :registry, default: Config::DEFAULT_REGISTRY
            end
          end
        rescue LoadError
          # @api private
          def config
            @config ||= Container::Config.new
          end
        end

        # @api private
        def configure
          yield config
        end
      end
    end
  end
end
