# frozen_string_literal: true

module RuboCop
  module Cop
    # Handles `Max` configuration parameters, especially setting them to an
    # appropriate value with --auto-gen-config.
    # @deprecated Use `exclude_limit <ParameterName>` instead.
    module ConfigurableMax
      private

      def max=(value)
        warn Rainbow(<<~WARNING).yellow, uplevel: 1
          `max=` is deprecated. Use `exclude_limit <ParameterName>` instead.
        WARNING

        cfg = config_to_allow_offenses
        cfg[:exclude_limit] ||= {}
        current_max = cfg[:exclude_limit][max_parameter_name]
        value = [current_max, value].max if current_max
        cfg[:exclude_limit][max_parameter_name] = value
      end

      def max_parameter_name
        'Max'
      end
    end
  end
end
