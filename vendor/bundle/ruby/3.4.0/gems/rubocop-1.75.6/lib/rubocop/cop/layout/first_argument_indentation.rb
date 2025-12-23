# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks the indentation of the first argument in a method call.
      # Arguments after the first one are checked by `Layout/ArgumentAlignment`,
      # not by this cop.
      #
      # For indenting the first parameter of method _definitions_, check out
      # `Layout/FirstParameterIndentation`.
      #
      # This cop will respect `Layout/ArgumentAlignment` and will not work when
      # `EnforcedStyle: with_fixed_indentation` is specified for `Layout/ArgumentAlignment`.
      #
      # @example
      #
      #   # bad
      #   some_method(
      #   first_param,
      #   second_param)
      #
      #   foo = some_method(
      #   first_param,
      #   second_param)
      #
      #   foo = some_method(nested_call(
      #   nested_first_param),
      #   second_param)
      #
      #   foo = some_method(
      #   nested_call(
      #   nested_first_param),
      #   second_param)
      #
      #   some_method nested_call(
      #   nested_first_param),
      #   second_param
      #
      # @example EnforcedStyle: special_for_inner_method_call_in_parentheses (default)
      #   # Same as `special_for_inner_method_call` except that the special rule
      #   # only applies if the outer method call encloses its arguments in
      #   # parentheses.
      #
      #   # good
      #   some_method(
      #     first_param,
      #   second_param)
      #
      #   foo = some_method(
      #     first_param,
      #   second_param)
      #
      #   foo = some_method(nested_call(
      #                       nested_first_param),
      #   second_param)
      #
      #   foo = some_method(
      #     nested_call(
      #       nested_first_param),
      #   second_param)
      #
      #   some_method nested_call(
      #     nested_first_param),
      #   second_param
      #
      # @example EnforcedStyle: consistent
      #   # The first argument should always be indented one step more than the
      #   # preceding line.
      #
      #   # good
      #   some_method(
      #     first_param,
      #   second_param)
      #
      #   foo = some_method(
      #     first_param,
      #   second_param)
      #
      #   foo = some_method(nested_call(
      #     nested_first_param),
      #   second_param)
      #
      #   foo = some_method(
      #     nested_call(
      #       nested_first_param),
      #   second_param)
      #
      #   some_method nested_call(
      #     nested_first_param),
      #   second_param
      #
      # @example EnforcedStyle: consistent_relative_to_receiver
      #   # The first argument should always be indented one level relative to
      #   # the parent that is receiving the argument
      #
      #   # good
      #   some_method(
      #     first_param,
      #   second_param)
      #
      #   foo = some_method(
      #           first_param,
      #   second_param)
      #
      #   foo = some_method(nested_call(
      #                       nested_first_param),
      #   second_param)
      #
      #   foo = some_method(
      #           nested_call(
      #             nested_first_param),
      #   second_param)
      #
      #   some_method nested_call(
      #                 nested_first_param),
      #   second_params
      #
      # @example EnforcedStyle: special_for_inner_method_call
      #   # The first argument should normally be indented one step more than
      #   # the preceding line, but if it's an argument for a method call that
      #   # is itself an argument in a method call, then the inner argument
      #   # should be indented relative to the inner method.
      #
      #   # good
      #   some_method(
      #     first_param,
      #   second_param)
      #
      #   foo = some_method(
      #     first_param,
      #   second_param)
      #
      #   foo = some_method(nested_call(
      #                       nested_first_param),
      #   second_param)
      #
      #   foo = some_method(
      #     nested_call(
      #       nested_first_param),
      #   second_param)
      #
      #   some_method nested_call(
      #                 nested_first_param),
      #   second_param
      #
      class FirstArgumentIndentation < Base
        include Alignment
        include ConfigurableEnforcedStyle
        include RangeHelp
        extend AutoCorrector

        MSG = 'Indent the first argument one step more than %<base>s.'

        def on_send(node)
          return unless should_check?(node)
          return if same_line?(node, node.first_argument)
          return if style != :consistent && enforce_first_argument_with_fixed_indentation? &&
                    !enable_layout_first_method_argument_line_break?

          indent = base_indentation(node) + configured_indentation_width

          check_alignment([node.first_argument], indent)
        end
        alias on_csend on_send
        alias on_super on_send

        private

        def should_check?(node)
          node.arguments? && !bare_operator?(node) && !node.setter_method?
        end

        def autocorrect(corrector, node)
          AlignmentCorrector.correct(corrector, processed_source, node, column_delta)
        end

        def bare_operator?(node)
          node.operator_method? && !node.dot?
        end

        def message(arg_node)
          return 'Bad indentation of the first argument.' unless arg_node

          send_node = arg_node.parent
          text = base_range(send_node, arg_node).source.strip
          base = if !text.include?("\n") && special_inner_call_indentation?(send_node)
                   "`#{text}`"
                 elsif comment_line?(text.lines.reverse_each.first)
                   'the start of the previous line (not counting the comment)'
                 else
                   'the start of the previous line'
                 end

          format(MSG, base: base)
        end

        def base_indentation(node)
          if special_inner_call_indentation?(node)
            column_of(base_range(node, node.first_argument))
          else
            previous_code_line(node.first_argument.first_line) =~ /\S/
          end
        end

        def special_inner_call_indentation?(node)
          return false if style == :consistent
          return true  if style == :consistent_relative_to_receiver

          parent = node.parent

          return false unless eligible_method_call?(parent)
          return false if !parent.parenthesized? &&
                          style == :special_for_inner_method_call_in_parentheses

          # The node must begin inside the parent, otherwise node is the first
          # part of a chained method call.
          node.source_range.begin_pos > parent.source_range.begin_pos
        end

        # @!method eligible_method_call?(node)
        def_node_matcher :eligible_method_call?, <<~PATTERN
          (send _ !:[]= ...)
        PATTERN

        def base_range(send_node, arg_node)
          parent = send_node.parent
          start_node = if parent&.type?(:splat, :kwsplat)
                         send_node.parent
                       else
                         send_node
                       end
          range_between(start_node.source_range.begin_pos, arg_node.source_range.begin_pos)
        end

        # Returns the column of the given range. For single line ranges, this
        # is simple. For ranges with line breaks, we look a the last code line.
        def column_of(range)
          source = range.source.strip
          if source.include?("\n")
            previous_code_line(range.line + source.count("\n") + 1) =~ /\S/
          else
            display_column(range)
          end
        end

        # Takes the line number of a given code line and returns a string
        # containing the previous line that's not a comment line or a blank
        # line.
        def previous_code_line(line_number)
          line = ''
          while line.blank? || comment_lines.include?(line_number)
            line_number -= 1
            line = processed_source.lines[line_number - 1]
          end
          line
        end

        def comment_lines
          @comment_lines ||=
            processed_source
            .comments
            .select { |c| begins_its_line?(c.source_range) }
            .map { |c| c.loc.line }
        end

        def on_new_investigation
          @comment_lines = nil
        end

        def enforce_first_argument_with_fixed_indentation?
          argument_alignment_config = config.for_enabled_cop('Layout/ArgumentAlignment')
          argument_alignment_config['EnforcedStyle'] == 'with_fixed_indentation'
        end

        def enable_layout_first_method_argument_line_break?
          config.cop_enabled?('Layout/FirstMethodArgumentLineBreak')
        end
      end
    end
  end
end
