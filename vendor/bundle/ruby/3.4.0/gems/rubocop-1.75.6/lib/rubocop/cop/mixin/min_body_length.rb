# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for checking minimum body length.
    module MinBodyLength
      private

      def min_body_length?(node)
        (node.loc.end.line - node.loc.keyword.line) > min_body_length
      end

      def min_body_length
        length = cop_config['MinBodyLength'] || 1
        return length if length.is_a?(Integer) && length.positive?

        raise 'MinBodyLength needs to be a positive integer!'
      end
    end
  end
end
