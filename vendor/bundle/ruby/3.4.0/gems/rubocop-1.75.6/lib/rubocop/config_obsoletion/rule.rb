# frozen_string_literal: true

module RuboCop
  class ConfigObsoletion
    # Abstract base class for ConfigObsoletion rules
    # @api private
    class Rule
      def initialize(config)
        @config = config
      end

      # Does this rule relate to cops?
      def cop_rule?
        false
      end

      # Does this rule relate to parameters?
      def parameter_rule?
        false
      end

      def violated?
        raise NotImplementedError
      end

      private

      attr_reader :config

      def to_sentence(collection, connector: 'and')
        return collection.first if collection.size == 1

        [collection[0..-2].join(', '), collection[-1]].join(" #{connector} ")
      end

      def smart_loaded_path
        PathUtil.smart_path(config.loaded_path)
      end
    end
  end
end
