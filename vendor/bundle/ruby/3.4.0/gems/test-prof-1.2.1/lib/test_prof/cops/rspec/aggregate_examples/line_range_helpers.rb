# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      class AggregateExamples < ::RuboCop::Cop::Cop
        # @internal Support methods for keeping newlines around examples.
        module LineRangeHelpers
          include RangeHelp

          private

          def range_for_replace(examples)
            range = range_by_whole_lines(examples.first.source_range,
              include_final_newline: true)
            next_range = range_by_whole_lines(examples[1].source_range)
            if adjacent?(range, next_range)
              range.resize(range.length + 1)
            else
              range
            end
          end

          def adjacent?(range, another_range)
            range.end_pos + 1 == another_range.begin_pos
          end
        end
      end
    end
  end
end
