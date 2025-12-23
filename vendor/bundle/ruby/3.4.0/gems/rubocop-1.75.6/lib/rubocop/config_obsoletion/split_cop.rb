# frozen_string_literal: true

module RuboCop
  class ConfigObsoletion
    # Encapsulation of a ConfigObsoletion rule for splitting a cop's
    # functionality into multiple new cops.
    # @api private
    class SplitCop < CopRule
      attr_reader :metadata

      def initialize(config, old_name, metadata)
        super(config, old_name)
        @metadata = metadata
      end

      def rule_message
        "The `#{old_name}` cop has been split into #{to_sentence(alternatives)}."
      end

      private

      def alternatives
        Array(metadata['alternatives']).map { |name| "`#{name}`" }
      end
    end
  end
end
