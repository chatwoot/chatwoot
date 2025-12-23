# frozen_string_literal: true

module RuboCop
  module Cop
    # This class does autocorrection of nodes that should just be moved to
    # the left or to the right, amount being determined by the instance
    # variable column_delta.
    class AlignmentCorrector
      extend RangeHelp
      extend Alignment

      class << self
        attr_reader :processed_source

        def correct(corrector, processed_source, node, column_delta)
          return unless node

          @processed_source = processed_source
          expr = node.respond_to?(:loc) ? node.source_range : node
          return if block_comment_within?(expr)

          taboo_ranges = inside_string_ranges(node)

          each_line(expr) do |line_begin_pos|
            autocorrect_line(corrector, line_begin_pos, expr, column_delta, taboo_ranges)
          end
        end

        def align_end(corrector, processed_source, node, align_to)
          @processed_source = processed_source
          whitespace = whitespace_range(node)
          return false unless whitespace.source.strip.empty?

          column = alignment_column(align_to)
          corrector.replace(whitespace, ' ' * column)
        end

        private

        def autocorrect_line(corrector, line_begin_pos, expr, column_delta,
                             taboo_ranges)
          range = calculate_range(expr, line_begin_pos, column_delta)
          # We must not change indentation of heredoc strings or inside other
          # string literals
          return if taboo_ranges.any? { |t| within?(range, t) }

          if column_delta.positive? && range.resize(1).source != "\n"
            corrector.insert_before(range, ' ' * column_delta)
          elsif /\A[ \t]+\z/.match?(range.source)
            corrector.remove(range)
          end
        end

        def inside_string_ranges(node)
          return [] unless node.is_a?(Parser::AST::Node)

          node.each_node(:str, :dstr, :xstr).filter_map { |n| inside_string_range(n) }
        end

        def inside_string_range(node)
          loc = node.location

          if node.heredoc?
            loc.heredoc_body.join(loc.heredoc_end)
          elsif delimited_string_literal?(node)
            loc.begin.end.join(loc.end.begin)
          end
        end

        # Some special kinds of string literals are not composed of literal
        # characters between two delimiters:
        # - The source map of `?a` responds to :begin and :end but its end is
        #   nil.
        # - The source map of `__FILE__` responds to neither :begin nor :end.
        def delimited_string_literal?(node)
          loc = node.location

          loc.respond_to?(:begin) && loc.begin && loc.respond_to?(:end) && loc.end
        end

        def block_comment_within?(expr)
          processed_source.comments.select(&:document?).any? do |c|
            within?(c.source_range, expr)
          end
        end

        def calculate_range(expr, line_begin_pos, column_delta)
          return range_between(line_begin_pos, line_begin_pos) if column_delta.positive?

          starts_with_space = expr.source_buffer.source[line_begin_pos].start_with?(' ')

          if starts_with_space
            range_between(line_begin_pos, line_begin_pos + column_delta.abs)
          else
            range_between(line_begin_pos - column_delta.abs, line_begin_pos)
          end
        end

        def each_line(expr)
          line_begin_pos = expr.begin_pos
          expr.source.each_line do |line|
            yield line_begin_pos
            line_begin_pos += line.length
          end
        end

        def whitespace_range(node)
          begin_pos = node.loc.end.begin_pos

          range_between(begin_pos - node.loc.end.column, begin_pos)
        end

        def alignment_column(align_to)
          if !align_to
            0
          elsif align_to.respond_to?(:loc)
            align_to.source_range.column
          else
            align_to.column
          end
        end
      end
    end
  end
end
