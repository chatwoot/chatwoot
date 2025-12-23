# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks the indentation of the method name part in method calls
      # that span more than one line.
      #
      # @example EnforcedStyle: aligned (default)
      #   # bad
      #   while myvariable
      #   .b
      #     # do something
      #   end
      #
      #   # good
      #   while myvariable
      #         .b
      #     # do something
      #   end
      #
      #   # good
      #   Thing.a
      #        .b
      #        .c
      #
      # @example EnforcedStyle: indented
      #   # good
      #   while myvariable
      #     .b
      #
      #     # do something
      #   end
      #
      # @example EnforcedStyle: indented_relative_to_receiver
      #   # good
      #   while myvariable
      #           .a
      #           .b
      #
      #     # do something
      #   end
      #
      #   # good
      #   myvariable = Thing
      #                  .a
      #                  .b
      #                  .c
      class MultilineMethodCallIndentation < Base
        include ConfigurableEnforcedStyle
        include Alignment
        include MultilineExpressionIndentation
        extend AutoCorrector

        def validate_config
          return unless style == :aligned && cop_config['IndentationWidth']

          raise ValidationError,
                'The `Layout/MultilineMethodCallIndentation` ' \
                'cop only accepts an `IndentationWidth` ' \
                'configuration parameter when ' \
                '`EnforcedStyle` is `indented`.'
        end

        private

        def autocorrect(corrector, node)
          AlignmentCorrector.correct(corrector, processed_source, node, @column_delta)
        end

        def relevant_node?(send_node)
          send_node.loc.dot # Only check method calls with dot operator
        end

        def right_hand_side(send_node)
          dot = send_node.loc.dot
          selector = send_node.loc.selector
          if (send_node.dot? || send_node.safe_navigation?) && selector && same_line?(dot, selector)
            dot.join(selector)
          elsif selector
            selector
          elsif send_node.implicit_call?
            dot.join(send_node.loc.begin)
          end
        end

        def offending_range(node, lhs, rhs, given_style)
          return false unless begins_its_line?(rhs)
          return false if not_for_this_cop?(node)

          @base = alignment_base(node, rhs, given_style)
          correct_column = if @base
                             @base.column + extra_indentation(given_style, node.parent)
                           else
                             indentation(lhs) + correct_indentation(node)
                           end
          @column_delta = correct_column - rhs.column
          rhs if @column_delta.nonzero?
        end

        def extra_indentation(given_style, parent)
          if given_style == :indented_relative_to_receiver
            if parent&.type?(:splat, :kwsplat)
              configured_indentation_width - parent.loc.operator.length
            else
              configured_indentation_width
            end
          else
            0
          end
        end

        def message(node, lhs, rhs)
          if should_indent_relative_to_receiver?
            relative_to_receiver_message(rhs)
          elsif should_align_with_base?
            align_with_base_message(rhs)
          else
            no_base_message(lhs, rhs, node)
          end
        end

        def should_indent_relative_to_receiver?
          @base && style == :indented_relative_to_receiver
        end

        def should_align_with_base?
          @base && style != :indented_relative_to_receiver
        end

        def relative_to_receiver_message(rhs)
          "Indent `#{rhs.source}` #{configured_indentation_width} spaces " \
            "more than `#{base_source}` on line #{@base.line}."
        end

        def align_with_base_message(rhs)
          "Align `#{rhs.source}` with `#{base_source}` on line #{@base.line}."
        end

        def base_source
          @base.source[/[^\n]*/]
        end

        def no_base_message(lhs, rhs, node)
          used_indentation = rhs.column - indentation(lhs)
          what = operation_description(node, rhs)

          "Use #{correct_indentation(node)} (not #{used_indentation}) " \
            "spaces for indenting #{what} spanning multiple lines."
        end

        def alignment_base(node, rhs, given_style)
          case given_style
          when :aligned
            semantic_alignment_base(node, rhs) || syntactic_alignment_base(node, rhs)
          when :indented
            nil
          when :indented_relative_to_receiver
            receiver_alignment_base(node)
          end
        end

        def syntactic_alignment_base(lhs, rhs)
          # a if b
          #      .c
          kw_node_with_special_indentation(lhs) do |base|
            return indented_keyword_expression(base).source_range
          end

          # a = b
          #     .c
          part_of_assignment_rhs(lhs, rhs) { |base| return assignment_rhs(base).source_range }

          # a + b
          #     .c
          operation_rhs(lhs) { |base| return base.source_range }
        end

        # a.b
        #  .c
        def semantic_alignment_base(node, rhs)
          return unless rhs.source.start_with?('.', '&.')

          node = semantic_alignment_node(node)
          return unless node&.loc&.selector && node.loc.dot

          node.loc.dot.join(node.loc.selector)
        end

        # a
        #   .b
        #   .c
        def receiver_alignment_base(node)
          node = node.receiver while node.receiver
          node = node.parent
          node = node.parent until node.loc.dot

          node&.receiver&.source_range
        end

        def semantic_alignment_node(node)
          return if argument_in_method_call(node, :with_parentheses)

          dot_right_above = get_dot_right_above(node)
          return dot_right_above if dot_right_above

          if (multiline_block_chain_node = find_multiline_block_chain_node(node))
            return multiline_block_chain_node
          end

          node = first_call_has_a_dot(node)
          return if node.loc.dot.line != node.first_line

          node
        end

        def get_dot_right_above(node)
          node.each_ancestor.find do |a|
            dot = a.loc.dot if a.loc?(:dot)
            next unless dot

            dot.line == node.loc.dot.line - 1 && dot.column == node.loc.dot.column
          end
        end

        def find_multiline_block_chain_node(node)
          return unless (block_node = node.each_descendant(:any_block).first)
          return unless block_node.multiline? && block_node.parent.call_type?

          if node.receiver.call_type?
            node.receiver
          else
            block_node.parent
          end
        end

        def first_call_has_a_dot(node)
          # descend to root of method chain
          node = node.receiver while node.receiver
          # ascend to first call which has a dot
          node = node.parent
          node = node.parent until node.loc?(:dot)

          node
        end

        def operation_rhs(node)
          operation_rhs = node.receiver.each_ancestor(:send).find do |rhs|
            operator_rhs?(rhs, node.receiver)
          end

          return unless operation_rhs

          yield operation_rhs.first_argument
        end

        def operator_rhs?(node, receiver)
          node.operator_method? && node.arguments? && within_node?(receiver, node.first_argument)
        end
      end
    end
  end
end
