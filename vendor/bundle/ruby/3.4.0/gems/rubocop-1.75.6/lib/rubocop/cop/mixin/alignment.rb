# frozen_string_literal: true

module RuboCop
  module Cop
    # This module checks for nodes that should be aligned to the left or right.
    # This amount is determined by the instance variable @column_delta.
    module Alignment
      SPACE = ' '

      private

      attr_reader :column_delta

      def configured_indentation_width
        cop_config['IndentationWidth'] || config.for_cop('Layout/IndentationWidth')['Width'] || 2
      end

      def indentation(node)
        offset(node) + (SPACE * configured_indentation_width)
      end

      def offset(node)
        SPACE * node.loc.column
      end

      def check_alignment(items, base_column = nil)
        base_column ||= display_column(items.first.source_range) unless items.empty?

        each_bad_alignment(items, base_column) do |current|
          expr = current.source_range
          if @current_offenses&.any? { |o| within?(expr, o.location) }
            # If this offense is within a line range that is already being
            # realigned by autocorrect, we report the offense without
            # autocorrecting it. Two rewrites in the same area by the same
            # cop cannot be handled. The next iteration will find the
            # offense again and correct it.
            register_offense(expr, nil)
          else
            register_offense(current, current)
          end
        end
      end

      # @api private
      def each_bad_alignment(items, base_column)
        prev_line = -1
        items.each do |current|
          if current.loc.line > prev_line && begins_its_line?(current.source_range)
            @column_delta = base_column - display_column(current.source_range)

            yield current if @column_delta.nonzero?
          end
          prev_line = current.loc.line
        end
      end

      # @api public
      def display_column(range)
        line = processed_source.lines[range.line - 1]
        Unicode::DisplayWidth.of(line[0, range.column])
      end

      # @api public
      def within?(inner, outer)
        inner.begin_pos >= outer.begin_pos && inner.end_pos <= outer.end_pos
      end

      # @deprecated Use processed_source.line_with_comment?(line)
      def end_of_line_comment(line)
        warn Rainbow(<<~WARNING).yellow, uplevel: 1
          `end_of_line_comment` is deprecated. Use `processed_source.line_with_comment?` instead.
        WARNING

        processed_source.line_with_comment?(line)
      end

      # @api private
      def register_offense(offense_node, message_node)
        add_offense(offense_node, message: message(message_node)) do |corrector|
          autocorrect(corrector, message_node)
        end
      end
    end
  end
end
