# frozen_string_literal: true

module RuboCop
  class ConfigObsoletion
    # Base class for ConfigObsoletion rules relating to parameters
    # @api private
    class ParameterRule < Rule
      attr_reader :cop, :parameter, :metadata

      def initialize(config, cop, parameter, metadata)
        super(config)
        @cop = cop
        @parameter = parameter
        @metadata = metadata
      end

      def parameter_rule?
        true
      end

      def violated?
        applies_to_current_ruby_version? && config[cop]&.key?(parameter)
      end

      def warning?
        severity == 'warning'
      end

      private

      def applies_to_current_ruby_version?
        minimum_ruby_version = metadata['minimum_ruby_version']

        return true unless minimum_ruby_version

        config.target_ruby_version >= minimum_ruby_version
      end

      def alternative
        metadata['alternative']
      end

      def alternatives
        metadata['alternatives']
      end

      def reason
        metadata['reason']
      end

      def severity
        metadata['severity']
      end
    end
  end
end
