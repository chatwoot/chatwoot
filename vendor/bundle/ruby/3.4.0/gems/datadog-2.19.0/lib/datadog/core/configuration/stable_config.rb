# frozen_string_literal: true

module Datadog
  module Core
    module Configuration
      # Import config from config files (fleet automation)
      module StableConfig
        def self.extract_configuration
          if (libdatadog_api_failure = Datadog::Core::LIBDATADOG_API_FAILURE)
            Datadog.config_init_logger.debug("Cannot enable stable config: #{libdatadog_api_failure}")
            return {}
          end
          Configurator.new.get
        end

        def self.configuration
          @configuration ||= StableConfig.extract_configuration
        end
      end
    end
  end
end
