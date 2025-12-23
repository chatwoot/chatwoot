# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks how the `when` and ``in``s of a `case` expression
      # are indented in relation to its `case` or `end` keyword.
      #
      # It will register a separate offense for each misaligned `when` and `in`.
      #
      # @example
      #   # If Layout/EndAlignment is set to keyword style (default)
      #   # *case* and *end* should always be aligned to same depth,
      #   # and therefore *when* should always be aligned to both -
      #   # regardless of configuration.
      #
      #   # bad for all styles
      #   case n
      #     when 0
      #       x * 2
      #     else
      #       y / 3
      #   end
      #
      #   case n
      #     in pattern
      #       x * 2
      #     else
      #       y / 3
      #   end
      #
      #   # good for all styles
      #   case n
      #   when 0
      #     x * 2
      #   else
      #     y / 3
      #   end
      #
      #   case n
      #   in pattern
      #     x * 2
      #   else
      #     y / 3
      #   end
      #
      # @example EnforcedStyle: case (default)
      #   # if EndAlignment is set to other style such as
      #   # start_of_line (as shown below), then *when* alignment
      #   # configuration does have an effect.
      #
      #   # bad
      #   a = case n
      #   when 0
      #     x * 2
      #   else
      #     y / 3
      #   end
      #
      #   a = case n
      #   in pattern
      #     x * 2
      #   else
      #     y / 3
      #   end
      #
      #   # good
      #   a = case n
      #       when 0
      #         x * 2
      #       else
      #         y / 3
      #   end
      #
      #   a = case n
      #       in pattern
      #         x * 2
      #       else
      #         y / 3
      #   end
      #
      # @example EnforcedStyle: end
      #   # bad
      #   a = case n
      #       when 0
      #         x * 2
      #       else
      #         y / 3
      #   end
      #
      #   a = case n
      #       in pattern
      #         x * 2
      #       else
      #         y / 3
      #   end
      #
      #   # good
      #   a = case n
      #   when 0
      #     x * 2
      #   else
      #     y / 3
      #   end
      #
      #   a = case n
      #   in pattern
      #     x * 2
      #   else
      #     y / 3
      #   end
      class CaseIndentation < Base
        include Alignment
        include ConfigurableEnforcedStyle
        include RangeHelp
        extend AutoCorrector

        MSG = 'Indent `%<branch_type>s` %<depth>s `%<base>s`.'

        def on_case(case_node)
          return if case_node.single_line?
          return if enforced_style_end? && end_and_last_conditional_same_line?(case_node)

          case_node.when_branches.each { |when_node| check_when(when_node, 'when') }
        end

        def on_case_match(case_match_node)
          return if case_match_node.single_line?
          return if enforced_style_end? && end_and_last_conditional_same_line?(case_match_node)

          case_match_node.each_in_pattern { |in_pattern_node| check_when(in_pattern_node, 'in') }
        end

        private

        def end_and_last_conditional_same_line?(node)
          end_line = node.loc.end&.line
          last_conditional_line = if node.loc.else
                                    node.loc.else.line
                                  else
                                    node.child_nodes.last.loc.begin&.line
                                  end
          end_line && last_conditional_line && end_line == last_conditional_line
        end

        def enforced_style_end?
          cop_config[style_parameter_name] == 'end'
        end

        def check_when(when_node, branch_type)
          when_column = when_node.loc.keyword.column
          base_column = base_column(when_node.parent, style)

          if when_column == base_column + indentation_width
            correct_style_detected
          else
            incorrect_style(when_node, branch_type)
          end
        end

        def indent_one_step?
          cop_config['IndentOneStep']
        end

        def indentation_width
          indent_one_step? ? configured_indentation_width : 0
        end

        def incorrect_style(when_node, branch_type)
          depth = indent_one_step? ? 'one step more than' : 'as deep as'
          message = format(MSG, branch_type: branch_type, depth: depth, base: style)

          add_offense(when_node.loc.keyword, message: message) do |corrector|
            detect_incorrect_style(when_node)

            whitespace = whitespace_range(when_node)

            corrector.replace(whitespace, replacement(when_node)) if whitespace.source.strip.empty?
          end
        end

        def detect_incorrect_style(when_node)
          when_column = when_node.loc.keyword.column
          base_column = base_column(when_node.parent, alternative_style)

          if when_column == base_column
            opposite_style_detected
          else
            unrecognized_style_detected
          end
        end

        def base_column(case_node, base)
          case base
          when :case then case_node.location.keyword.column
          when :end  then case_node.location.end.column
          end
        end

        def whitespace_range(node)
          when_column = node.location.keyword.column
          begin_pos = node.loc.keyword.begin_pos

          range_between(begin_pos - when_column, begin_pos)
        end

        def replacement(node)
          case_node = node.each_ancestor(:case, :case_match).first
          base_type = cop_config[style_parameter_name] == 'end' ? :end : :case

          column = base_column(case_node, base_type)
          column += indentation_width

          ' ' * column
        end
      end
    end
  end
end
