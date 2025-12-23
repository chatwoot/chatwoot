# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Access modifiers should be surrounded by blank lines.
      #
      # @example EnforcedStyle: around (default)
      #
      #   # bad
      #   class Foo
      #     def bar; end
      #     private
      #     def baz; end
      #   end
      #
      #   # good
      #   class Foo
      #     def bar; end
      #
      #     private
      #
      #     def baz; end
      #   end
      #
      # @example EnforcedStyle: only_before
      #
      #   # bad
      #   class Foo
      #     def bar; end
      #     private
      #     def baz; end
      #   end
      #
      #   # good
      #   class Foo
      #     def bar; end
      #
      #     private
      #     def baz; end
      #   end
      #
      class EmptyLinesAroundAccessModifier < Base
        include ConfigurableEnforcedStyle
        include RangeHelp
        extend AutoCorrector

        MSG_AFTER = 'Keep a blank line after `%<modifier>s`.'
        MSG_BEFORE_AND_AFTER = 'Keep a blank line before and after `%<modifier>s`.'

        MSG_BEFORE_FOR_ONLY_BEFORE = 'Keep a blank line before `%<modifier>s`.'
        MSG_AFTER_FOR_ONLY_BEFORE = 'Remove a blank line after `%<modifier>s`.'

        RESTRICT_ON_SEND = %i[public protected private module_function].freeze

        def initialize(config = nil, options = nil)
          super

          @block_line = nil
        end

        def on_class(node)
          @class_or_module_def_first_line = if node.parent_class
                                              node.parent_class.first_line
                                            else
                                              node.source_range.first_line
                                            end
          @class_or_module_def_last_line = node.source_range.last_line
        end

        def on_module(node)
          @class_or_module_def_first_line = node.source_range.first_line
          @class_or_module_def_last_line = node.source_range.last_line
        end

        def on_sclass(node)
          @class_or_module_def_first_line = node.identifier.source_range.first_line
          @class_or_module_def_last_line = node.source_range.last_line
        end

        def on_block(node)
          @block_line = node.source_range.first_line
        end

        alias on_numblock on_block
        alias on_itblock on_block

        def on_send(node)
          return unless node.bare_access_modifier? && !node.block_literal?
          return if same_line?(node, node.right_sibling)
          return if expected_empty_lines?(node)

          message = message(node)
          add_offense(node, message: message) do |corrector|
            line = range_by_whole_lines(node.source_range)

            corrector.insert_before(line, "\n") if should_insert_line_before?(node)

            correct_next_line_if_denied_style(corrector, node, line)
          end
        end

        private

        def expected_empty_lines?(node)
          case style
          when :around
            return true if empty_lines_around?(node)
          when :only_before
            return true if allowed_only_before_style?(node)
          end

          false
        end

        def allowed_only_before_style?(node)
          if node.special_modifier?
            return true if processed_source[node.last_line] == 'end'
            return false if next_line_empty?(node.last_line)
          end

          previous_line_empty?(node.first_line)
        end

        def correct_next_line_if_denied_style(corrector, node, line)
          return unless should_insert_line_after?(node)

          case style
          when :around
            corrector.insert_after(line, "\n") unless next_line_empty?(node.last_line)
          when :only_before
            if next_line_empty?(node.last_line)
              range = next_empty_line_range(node)

              corrector.remove(range)
            end
          end
        end

        def previous_line_ignoring_comments(processed_source, send_line)
          processed_source[0..send_line - 2].reverse.find { |line| !comment_line?(line) }
        end

        def previous_line_empty?(send_line)
          previous_line = previous_line_ignoring_comments(processed_source, send_line)
          return true unless previous_line

          block_start?(send_line) || class_def?(send_line) || previous_line.blank?
        end

        def next_line_empty?(last_send_line)
          next_line = processed_source[last_send_line]

          body_end?(last_send_line) || next_line.blank?
        end

        def empty_lines_around?(node)
          previous_line_empty?(node.first_line) && next_line_empty?(node.last_line)
        end

        def class_def?(line)
          return false unless @class_or_module_def_first_line

          line == @class_or_module_def_first_line + 1
        end

        def block_start?(line)
          return false unless @block_line

          line == @block_line + 1
        end

        def body_end?(line)
          return false unless @class_or_module_def_last_line

          line == @class_or_module_def_last_line - 1
        end

        def next_empty_line_range(node)
          source_range(processed_source.buffer, node.last_line + 1, 0)
        end

        def message(node)
          case style
          when :around
            message_for_around_style(node)
          when :only_before
            message_for_only_before_style(node)
          end
        end

        def message_for_around_style(node)
          send_line = node.first_line

          if block_start?(send_line) || class_def?(send_line)
            format(MSG_AFTER, modifier: node.loc.selector.source)
          else
            format(MSG_BEFORE_AND_AFTER, modifier: node.loc.selector.source)
          end
        end

        def message_for_only_before_style(node)
          modifier = node.loc.selector.source

          if next_line_empty?(node.last_line)
            format(MSG_AFTER_FOR_ONLY_BEFORE, modifier: modifier)
          else
            format(MSG_BEFORE_FOR_ONLY_BEFORE, modifier: modifier)
          end
        end

        def should_insert_line_before?(node)
          return false if previous_line_empty?(node.first_line)
          return true unless inside_block?(node) && no_empty_lines_around_block_body?
          return true unless node.parent.begin_type?

          node.parent.children.first != node
        end

        def should_insert_line_after?(node)
          return true unless inside_block?(node) && no_empty_lines_around_block_body?

          node.parent.children.last != node
        end

        def inside_block?(node)
          node.parent.block_type? || (node.parent.begin_type? && node.parent.parent&.block_type?)
        end

        def no_empty_lines_around_block_body?
          config.for_enabled_cop('Layout/EmptyLinesAroundBlockBody')['EnforcedStyle'] ==
            'no_empty_lines'
        end
      end
    end
  end
end
