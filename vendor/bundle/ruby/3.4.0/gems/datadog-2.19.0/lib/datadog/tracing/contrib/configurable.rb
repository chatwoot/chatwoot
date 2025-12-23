# frozen_string_literal: true

require_relative 'configuration/resolver'
require_relative 'configuration/settings'

module Datadog
  module Tracing
    module Contrib
      # Defines configurable behavior for integrations.
      #
      # This module is responsible for coordination between
      # the configuration resolver and default configuration
      # fallback.
      module Configurable
        def self.included(base)
          base.include(InstanceMethods)
        end

        # Configurable instance behavior for integrations
        module InstanceMethods
          # Get matching configuration by matcher.
          # If no match, returns the default configuration instance.
          def configuration(matcher = :default)
            return default_configuration if matcher == :default

            resolver.get(matcher) || default_configuration
          end

          # Resolves the matching configuration for integration-specific value.
          # If no match, returns the default configuration instance.
          def resolve(value)
            return default_configuration if value == :default

            resolver.resolve(value) || default_configuration
          end

          # Returns all registered matchers and their respective configurations.
          def configurations
            resolver.configurations.merge(default: default_configuration)
          end

          # Create or update configuration associated with `matcher` with
          # the provided `options` and `&block`.
          def configure(matcher = :default, options = {}, &block)
            config = if matcher == :default
                       default_configuration
                     else
                       # Get or add the configuration
                       resolver.get(matcher) || resolver.add(matcher, new_configuration)
                     end

            # Apply the settings
            config.configure(options, &block) if config
            config
          end

          # Resets all configuration options
          def reset_configuration!
            @resolver = nil
            @default_configuration = nil
          end

          # Returns the integration-specific configuration object.
          #
          # If one does not exist, invoke {.new_configuration} a memoize
          # its value.
          #
          # @return [Datadog::Tracing::Contrib::Configuration::Settings] the memoized integration-specific settings object
          def default_configuration
            @default_configuration ||= new_configuration
          end

          protected

          # Returns a new configuration object for this integration.
          #
          # This method normally needs to be overridden for each integration
          # as their settings, defaults and environment variables are
          # specific for each integration.
          #
          # @return [Datadog::Tracing::Contrib::Configuration::Settings] a new, integration-specific settings object
          def new_configuration
            Configuration::Settings.new
          end

          # Overridable configuration resolver.
          #
          # This resolver is responsible for performing the matching
          # of `#configure(matcher)` `matcher`s with `value`s provided
          # in subsequent calls to `#resolve(value)`.
          #
          # By default, the `value` in `#resolve(value)` must be equal
          # to the `matcher` object provided in `#configure(matcher)`
          # to retrieve the associated configuration.
          def resolver
            @resolver ||= Configuration::Resolver.new
          end
        end
      end
    end
  end
end
