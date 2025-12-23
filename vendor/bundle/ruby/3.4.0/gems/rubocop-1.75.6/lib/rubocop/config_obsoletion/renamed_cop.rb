# frozen_string_literal: true

module RuboCop
  class ConfigObsoletion
    # Encapsulation of a ConfigObsoletion rule for renaming
    # a cop or moving it to a new department.
    # @api private
    class RenamedCop < CopRule
      attr_reader :new_name, :metadata

      def initialize(config, old_name, name_or_hash)
        super(config, old_name)

        if name_or_hash.is_a?(Hash)
          @metadata = name_or_hash
          @new_name = name_or_hash['new_name']
        else
          @metadata = {}
          @new_name = name_or_hash
        end
      end

      def rule_message
        "The `#{old_name}` cop has been #{verb} to `#{new_name}`."
      end

      def warning?
        severity == 'warning'
      end

      private

      def moved?
        old_badge = Cop::Badge.parse(old_name)
        new_badge = Cop::Badge.parse(new_name)

        old_badge.department != new_badge.department && old_badge.cop_name == new_badge.cop_name
      end

      def verb
        moved? ? 'moved' : 'renamed'
      end

      def severity
        metadata['severity']
      end
    end
  end
end
