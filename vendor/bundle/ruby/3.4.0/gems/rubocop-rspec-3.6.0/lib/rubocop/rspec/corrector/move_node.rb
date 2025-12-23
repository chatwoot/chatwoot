# frozen_string_literal: true

module RuboCop
  module RSpec
    module Corrector
      # Helper methods to move a node
      class MoveNode
        include RuboCop::Cop::RangeHelp
        include RuboCop::Cop::RSpec::CommentsHelp
        include RuboCop::Cop::RSpec::FinalEndLocation

        attr_reader :original, :corrector, :processed_source

        def initialize(node, corrector, processed_source)
          @original = node
          @corrector = corrector
          @processed_source = processed_source # used by RangeHelp
        end

        def move_before(other)
          position = start_line_position(other)

          corrector.insert_before(position, "#{source(original)}\n")
          corrector.remove(node_range_with_surrounding_space(original))
        end

        def move_after(other)
          position = end_line_position(other)

          corrector.insert_after(position, "\n#{source(original)}")
          corrector.remove(node_range_with_surrounding_space(original))
        end

        private

        def source(node)
          node_range(node).source
        end

        def node_range(node)
          source_range_with_comment(node)
        end

        def node_range_with_surrounding_space(node)
          range = node_range(node)
          range_by_whole_lines(range, include_final_newline: true)
        end
      end
    end
  end
end
