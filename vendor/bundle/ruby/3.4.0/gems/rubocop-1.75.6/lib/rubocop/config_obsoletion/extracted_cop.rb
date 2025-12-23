# frozen_string_literal: true

module RuboCop
  class ConfigObsoletion
    # Encapsulation of a ConfigObsoletion rule for splitting a cop's
    # functionality into multiple new cops.
    # @api private
    class ExtractedCop < CopRule
      attr_reader :gem, :department

      def initialize(config, old_name, gem)
        super(config, old_name)
        @department, * = old_name.rpartition('/')
        @gem = gem
      end

      def violated?
        return false if plugin_loaded?

        affected_cops.any?
      end

      def rule_message
        msg = '%<name>s been extracted to the `%<gem>s` gem.'
        format(msg,
               name: affected_cops.size > 1 ? "`#{department}` cops have" : "`#{old_name}` has",
               gem: gem)
      end

      private

      def affected_cops
        return old_name unless old_name.end_with?('*')

        # Handle whole departments (expressed as `Department/*`)
        config.keys.select do |key|
          key == department || key.start_with?("#{department}/")
        end
      end

      def plugin_loaded?
        # Plugins loaded via `require` are included in `loaded_features`.
        config.loaded_plugins.include?(gem) || config.loaded_features.include?(gem)
      end
    end
  end
end
