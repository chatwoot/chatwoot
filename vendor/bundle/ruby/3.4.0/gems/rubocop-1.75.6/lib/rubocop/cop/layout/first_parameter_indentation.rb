# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks the indentation of the first parameter in a method
      # definition. Parameters after the first one are checked by
      # `Layout/ParameterAlignment`, not by this cop.
      #
      # For indenting the first argument of method _calls_, check out
      # `Layout/FirstArgumentIndentation`, which supports options related to
      # nesting that are irrelevant for method _definitions_.
      #
      # @example
      #
      #   # bad
      #   def some_method(
      #   first_param,
      #   second_param)
      #     123
      #   end
      #
      # @example EnforcedStyle: consistent (default)
      #   # The first parameter should always be indented one step more than the
      #   # preceding line.
      #
      #   # good
      #   def some_method(
      #     first_param,
      #   second_param)
      #     123
      #   end
      #
      # @example EnforcedStyle: align_parentheses
      #   # The first parameter should always be indented one step more than the
      #   # opening parenthesis.
      #
      #   # good
      #   def some_method(
      #                    first_param,
      #   second_param)
      #     123
      #   end
      class FirstParameterIndentation < Base
        include Alignment
        include ConfigurableEnforcedStyle
        include MultilineElementIndentation
        extend AutoCorrector

        MSG = 'Use %<configured_indentation_width>d spaces for indentation ' \
              'in method args, relative to %<base_description>s.'

        def on_def(node)
          return if node.arguments.empty?
          return if node.arguments.loc.begin.nil?

          check(node)
        end
        alias on_defs on_def

        private

        def autocorrect(corrector, node)
          AlignmentCorrector.correct(corrector, processed_source, node, @column_delta)
        end

        def brace_alignment_style
          :align_parentheses
        end

        def check(def_node)
          return if ignored_node?(def_node)

          left_parenthesis = def_node.arguments.loc.begin
          first_elem = def_node.first_argument
          return unless first_elem
          return if same_line?(first_elem, left_parenthesis)

          check_first(first_elem, left_parenthesis, nil, 0)
        end

        # Returns the description of what the correct indentation is based on.
        def base_description(_)
          if style == brace_alignment_style
            'the position of the opening parenthesis'
          else
            'the start of the line where the left parenthesis is'
          end
        end

        def message(base_description)
          format(
            MSG,
            configured_indentation_width: configured_indentation_width,
            base_description: base_description
          )
        end
      end
    end
  end
end
