# frozen_string_literal: true

module RuboCop
  class ConfigObsoletion
    # Base class for ConfigObsoletion rules relating to cops
    # @api private
    class CopRule < Rule
      attr_reader :old_name

      def initialize(config, old_name)
        super(config)
        @old_name = old_name
      end

      def cop_rule?
        true
      end

      def message
        rule_message + "\n(obsolete configuration found in #{smart_loaded_path}, please update it)"
      end

      # Cop rules currently can only be failures, not warnings
      def warning?
        false
      end

      def violated?
        config.key?(old_name) || config.key?(Cop::Badge.parse(old_name).cop_name)
      end
    end
  end
end
