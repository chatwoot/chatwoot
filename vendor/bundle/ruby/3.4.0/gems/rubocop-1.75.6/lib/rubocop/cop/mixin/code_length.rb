# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for checking length of code segments.
    module CodeLength
      extend ExcludeLimit

      MSG = '%<label>s has too many lines. [%<length>d/%<max>d]'

      exclude_limit 'Max'

      private

      def message(length, max_length)
        format(MSG, label: cop_label, length: length, max: max_length)
      end

      def max_length
        cop_config['Max']
      end

      def count_comments?
        cop_config['CountComments']
      end

      def count_as_one
        Array(cop_config['CountAsOne']).map(&:to_sym)
      end

      def check_code_length(node)
        # Skip costly calculation when definitely not needed
        return if node.line_count <= max_length

        calculator = build_code_length_calculator(node)
        length = calculator.calculate
        return if length <= max_length

        location = location(node)

        add_offense(location, message: message(length, max_length)) { self.max = length }
      end

      # Returns true for lines that shall not be included in the count.
      def irrelevant_line(source_line)
        source_line.blank? || (!count_comments? && comment_line?(source_line))
      end

      def build_code_length_calculator(node)
        Metrics::Utils::CodeLengthCalculator.new(
          node,
          processed_source,
          count_comments: count_comments?,
          foldable_types: count_as_one
        )
      end

      def location(node)
        return node.loc.name if node.casgn_type?

        if LSP.enabled?
          end_range = node.loc.respond_to?(:name) ? node.loc.name : node.loc.begin
          node.source_range.begin.join(end_range)
        else
          node.source_range
        end
      end
    end
  end
end
