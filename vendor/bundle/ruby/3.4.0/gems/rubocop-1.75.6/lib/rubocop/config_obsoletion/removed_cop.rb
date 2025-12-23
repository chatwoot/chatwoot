# frozen_string_literal: true

module RuboCop
  class ConfigObsoletion
    # Encapsulation of a ConfigObsoletion rule for removing
    # a previously defined cop.
    # @api private
    class RemovedCop < CopRule
      attr_reader :old_name, :metadata

      BASE_MESSAGE = 'The `%<old_name>s` cop has been removed'

      def initialize(config, old_name, metadata)
        super(config, old_name)
        @metadata = metadata.is_a?(Hash) ? metadata : {}
      end

      def rule_message
        base = format(BASE_MESSAGE, old_name: old_name)

        if reason
          "#{base} since #{reason.chomp}."
        elsif alternatives
          "#{base}. Please use #{to_sentence(alternatives, connector: 'and/or')} instead."
        else
          "#{base}."
        end
      end

      private

      def reason
        metadata['reason']
      end

      def alternatives
        Array(metadata['alternatives']).map { |name| "`#{name}`" }
      end
    end
  end
end
