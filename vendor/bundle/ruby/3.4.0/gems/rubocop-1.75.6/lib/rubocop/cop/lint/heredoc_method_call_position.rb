# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for the ordering of a method call where
      # the receiver of the call is a HEREDOC.
      #
      # @example
      #   # bad
      #   <<-SQL
      #     bar
      #   SQL
      #   .strip_indent
      #
      #   <<-SQL
      #     bar
      #   SQL
      #   .strip_indent
      #   .trim
      #
      #   # good
      #   <<~SQL
      #     bar
      #   SQL
      #
      #   <<~SQL.trim
      #     bar
      #   SQL
      #
      class HeredocMethodCallPosition < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Put a method call with a HEREDOC receiver on the same line as the HEREDOC opening.'

        def on_send(node)
          heredoc = heredoc_node_descendent_receiver(node)
          return unless heredoc
          return if correctly_positioned?(node, heredoc)

          add_offense(call_after_heredoc_range(heredoc)) do |corrector|
            autocorrect(corrector, node, heredoc)
          end
        end
        alias on_csend on_send

        private

        def autocorrect(corrector, node, heredoc)
          call_range = call_range_to_safely_reposition(node, heredoc)
          return if call_range.nil?

          call_source = call_range.source.strip
          corrector.remove(call_range)
          corrector.insert_after(heredoc_begin_line_range(node), call_source)
        end

        def heredoc_node_descendent_receiver(node)
          while send_node?(node)
            return node.receiver if heredoc_node?(node.receiver)

            node = node.receiver
          end
        end

        def send_node?(node)
          return false unless node

          node.call_type?
        end

        def heredoc_node?(node)
          node.respond_to?(:heredoc?) && node.heredoc?
        end

        def call_after_heredoc_range(heredoc)
          pos = heredoc_end_pos(heredoc)
          range_between(pos + 1, pos + 2)
        end

        def correctly_positioned?(node, heredoc)
          heredoc_end_pos(heredoc) > call_end_pos(node)
        end

        def calls_on_multiple_lines?(node, _heredoc)
          last_line = node.last_line
          while send_node?(node)
            return true unless last_line == node.last_line
            return true unless all_on_same_line?(node.arguments)

            node = node.receiver
          end
          false
        end

        def all_on_same_line?(nodes)
          return true if nodes.empty?

          nodes.first.first_line == nodes.last.last_line
        end

        def heredoc_end_pos(heredoc)
          heredoc.location.heredoc_end.end_pos
        end

        def call_end_pos(node)
          node.source_range.end_pos
        end

        def heredoc_begin_line_range(heredoc)
          pos = heredoc.source_range.begin_pos
          range_by_whole_lines(range_between(pos, pos))
        end

        def call_line_range(node)
          pos = node.source_range.end_pos
          range_by_whole_lines(range_between(pos, pos))
        end

        # Returns nil if no range can be safely repositioned.
        def call_range_to_safely_reposition(node, heredoc)
          return nil if calls_on_multiple_lines?(node, heredoc)

          heredoc_end_pos = heredoc_end_pos(heredoc)
          call_end_pos = call_end_pos(node)

          call_range = range_between(heredoc_end_pos, call_end_pos)
          call_line_range = call_line_range(node)

          call_source = call_range.source.strip
          call_line_source = call_line_range.source.strip

          return call_range if call_source == call_line_source

          if trailing_comma?(call_source, call_line_source)
            # If there's some on the last line other than the call, e.g.
            # a trailing comma, then we leave the "\n" following the
            # heredoc_end in place.
            return range_between(heredoc_end_pos, call_end_pos + 1)
          end

          nil
        end

        def trailing_comma?(call_source, call_line_source)
          "#{call_source}," == call_line_source
        end
      end
    end
  end
end
