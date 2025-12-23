# frozen_string_literal: true

require_relative 'configuration/container'

module JWT
  # The Configuration module provides methods to configure JWT settings.
  module Configuration
    # Configures the JWT settings.
    #
    # @yield [config] Gives the current configuration to the block.
    # @yieldparam config [JWT::Configuration::Container] the configuration container.
    def configure
      yield(configuration)
    end

    # Returns the JWT configuration container.
    #
    # @return [JWT::Configuration::Container] the configuration container.
    def configuration
      @configuration ||= ::JWT::Configuration::Container.new
    end
  end
end
