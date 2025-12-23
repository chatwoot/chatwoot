# frozen_string_literal: true

module Datadog
  module Tracing
    module Configuration
      module Dynamic
        # Maps a remote dynamic configuration to a location configuration option.
        class Option
          attr_reader :name, :env_var

          # @param name [String] dynamic configuration option name. This must match the remote configuration payload.
          def initialize(name, env_var)
            @name = name
            @env_var = env_var
          end

          # Reconfigures the provided option, setting its value to `value`.
          #
          # @param value [Object,nil] the new value for this option
          def call(value)
            raise NotImplementedError
          end
        end

        # A dynamic configuration option that can directly mapped to a `Datadog.configuration`
        # option and changing such option is the only requirement to apply the configuration locally.
        class SimpleOption < Option
          # @param name [String] dynamic configuration option name. This must match the remote configuration payload.
          # @param env_var [String] the canonical environment variable that represents this option.
          #   This is used for telemetry reporting.
          # @param setting_key [Symbol] option from `Datadog.configuration.tracing` that will be modified
          #
          # DEV: `Datadog.configuration` cannot be an argument default value because
          # DEV: it is dynamic. Also, it is not yet declared when this method is parsed by Ruby.
          def initialize(name, env_var, setting_key)
            super(name, env_var)
            @setting_key = setting_key
          end

          # Reconfigures the provided option, setting its value to `value`.
          #
          # @param value [Object,nil] the new value for this option
          def call(value)
            Datadog.logger.debug { "Reconfigured tracer option `#{@setting_key}` with value `#{value}`" }

            if value.nil?
              # Restore the local configuration value
              configuration_object.unset_option(
                @setting_key,
                precedence: Core::Configuration::Option::Precedence::REMOTE_CONFIGURATION
              )
            else
              configuration_object.set_option(
                @setting_key,
                value,
                precedence: Core::Configuration::Option::Precedence::REMOTE_CONFIGURATION
              )
            end
          end

          protected

          # The base where `setting_key` will apply
          def configuration_object
            Datadog.configuration.tracing
          end
        end
      end
    end
  end
end
