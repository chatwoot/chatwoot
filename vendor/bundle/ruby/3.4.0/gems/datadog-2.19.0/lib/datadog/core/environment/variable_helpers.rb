# frozen_string_literal: true

module Datadog
  module Core
    # Namespace for handling application environment
    module Environment
      # Defines helper methods for environment
      # @public_api
      module VariableHelpers
        extend self

        # Reads an environment variable as a Boolean.
        #
        # @param [String] var environment variable
        # @param [Array<String>] var list of environment variables
        # @param [Boolean] default the default value if the keys in `var` are not present in the environment
        # @param [Boolean] deprecation_warning when `var` is a list, record a deprecation log when
        #   the first key in `var` is not used.
        # @return [Boolean] if the environment value is the string `true` or `1`
        # @return [default] if the environment value is not found
        def env_to_bool(var, default = nil, deprecation_warning: true)
          var = decode_array(var, deprecation_warning)
          if var && ENV.key?(var)
            value = ENV[var].to_s.strip
            value.downcase!
            value == 'true' || value == '1'
          else
            default
          end
        end

        private

        def decode_array(var, deprecation_warning)
          if var.is_a?(Array)
            var.find.with_index do |env_var, i|
              found = ENV.key?(env_var)

              # Check if we are using a non-preferred environment variable
              if deprecation_warning && found && i != 0
                Datadog::Core.log_deprecation { "#{env_var} environment variable is deprecated, use #{var.first} instead." }
              end

              found
            end
          else
            var
          end
        end
      end
    end
  end
end
