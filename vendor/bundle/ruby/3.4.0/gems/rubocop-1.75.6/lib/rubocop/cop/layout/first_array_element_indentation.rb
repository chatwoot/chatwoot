# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks the indentation of the first element in an array literal
      # where the opening bracket and the first element are on separate lines.
      # The other elements' indentations are handled by `Layout/ArrayAlignment` cop.
      #
      # This cop will respect `Layout/ArrayAlignment` and will not work when
      # `EnforcedStyle: with_fixed_indentation` is specified for `Layout/ArrayAlignment`.
      #
      # By default, array literals that are arguments in a method call with
      # parentheses, and where the opening square bracket of the array is on the
      # same line as the opening parenthesis of the method call, shall have
      # their first element indented one step (two spaces) more than the
      # position inside the opening parenthesis.
      #
      # Other array literals shall have their first element indented one step
      # more than the start of the line where the opening square bracket is.
      #
      # This default style is called 'special_inside_parentheses'. Alternative
      # styles are 'consistent' and 'align_brackets'. Here are examples:
      #
      # @example EnforcedStyle: special_inside_parentheses (default)
      #   # The `special_inside_parentheses` style enforces that the first
      #   # element in an array literal where the opening bracket and first
      #   # element are on separate lines is indented one step (two spaces) more
      #   # than the position inside the opening parenthesis.
      #
      #   # bad
      #   array = [
      #     :value
      #   ]
      #   and_in_a_method_call([
      #     :no_difference
      #                        ])
      #
      #   # good
      #   array = [
      #     :value
      #   ]
      #   but_in_a_method_call([
      #                          :its_like_this
      #                        ])
      #
      # @example EnforcedStyle: consistent
      #   # The `consistent` style enforces that the first element in an array
      #   # literal where the opening bracket and the first element are on
      #   # separate lines is indented the same as an array literal which is not
      #   # defined inside a method call.
      #
      #   # bad
      #   array = [
      #     :value
      #   ]
      #   but_in_a_method_call([
      #                          :its_like_this
      #   ])
      #
      #   # good
      #   array = [
      #     :value
      #   ]
      #   and_in_a_method_call([
      #     :no_difference
      #   ])
      #
      # @example EnforcedStyle: align_brackets
      #   # The `align_brackets` style enforces that the opening and closing
      #   # brackets are indented to the same position.
      #
      #   # bad
      #   and_now_for_something = [
      #                             :completely_different
      #   ]
      #
      #   # good
      #   and_now_for_something = [
      #                             :completely_different
      #                           ]
      class FirstArrayElementIndentation < Base
        include Alignment
        include ConfigurableEnforcedStyle
        include MultilineElementIndentation
        extend AutoCorrector

        MSG = 'Use %<configured_indentation_width>d spaces for indentation ' \
              'in an array, relative to %<base_description>s.'

        def on_array(node)
          return if style != :consistent && enforce_first_argument_with_fixed_indentation?

          check(node, nil) if node.loc.begin
        end

        def on_send(node)
          return if style != :consistent && enforce_first_argument_with_fixed_indentation?

          each_argument_node(node, :array) do |array_node, left_parenthesis|
            check(array_node, left_parenthesis)
          end
        end
        alias on_csend on_send

        private

        def autocorrect(corrector, node)
          AlignmentCorrector.correct(corrector, processed_source, node, @column_delta)
        end

        def brace_alignment_style
          :align_brackets
        end

        def check(array_node, left_parenthesis)
          return if ignored_node?(array_node)

          left_bracket = array_node.loc.begin
          first_elem = array_node.values.first
          if first_elem
            return if same_line?(first_elem, left_bracket)

            check_first(first_elem, left_bracket, left_parenthesis, 0)
          end

          check_right_bracket(array_node.loc.end, first_elem, left_bracket, left_parenthesis)
        end

        def check_right_bracket(right_bracket, first_elem, left_bracket, left_parenthesis)
          # if the right bracket is on the same line as the last value, accept
          return if /\S/.match?(right_bracket.source_line[0...right_bracket.column])

          expected_column, indent_base_type = indent_base(left_bracket, first_elem,
                                                          left_parenthesis)
          @column_delta = expected_column - right_bracket.column
          return if @column_delta.zero?

          msg = message_for_right_bracket(indent_base_type)
          add_offense(right_bracket, message: msg) do |corrector|
            autocorrect(corrector, right_bracket)
          end
        end

        # Returns the description of what the correct indentation is based on.
        def base_description(indent_base_type)
          case indent_base_type
          when :left_brace_or_bracket
            'the position of the opening bracket'
          when :first_column_after_left_parenthesis
            'the first position after the preceding left parenthesis'
          when :parent_hash_key
            'the parent hash key'
          else
            'the start of the line where the left square bracket is'
          end
        end

        def message(base_description)
          format(
            MSG,
            configured_indentation_width: configured_indentation_width,
            base_description: base_description
          )
        end

        def message_for_right_bracket(indent_base_type)
          case indent_base_type
          when :left_brace_or_bracket
            'Indent the right bracket the same as the left bracket.'
          when :first_column_after_left_parenthesis
            'Indent the right bracket the same as the first position ' \
            'after the preceding left parenthesis.'
          when :parent_hash_key
            'Indent the right bracket the same as the parent hash key.' \
          else
            'Indent the right bracket the same as the start of the line ' \
            'where the left bracket is.'
          end
        end

        def enforce_first_argument_with_fixed_indentation?
          argument_alignment_config = config.for_enabled_cop('Layout/ArrayAlignment')
          argument_alignment_config['EnforcedStyle'] == 'with_fixed_indentation'
        end
      end
    end
  end
end
