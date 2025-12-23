# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks the indentation of the first key in a hash literal
      # where the opening brace and the first key are on separate lines. The
      # other keys' indentations are handled by the HashAlignment cop.
      #
      # By default, `Hash` literals that are arguments in a method call with
      # parentheses, and where the opening curly brace of the hash is on the
      # same line as the opening parenthesis of the method call, shall have
      # their first key indented one step (two spaces) more than the position
      # inside the opening parenthesis.
      #
      # Other hash literals shall have their first key indented one step more
      # than the start of the line where the opening curly brace is.
      #
      # This default style is called 'special_inside_parentheses'. Alternative
      # styles are 'consistent' and 'align_braces'. Here are examples:
      #
      # @example EnforcedStyle: special_inside_parentheses (default)
      #   # The `special_inside_parentheses` style enforces that the first key
      #   # in a hash literal where the opening brace and the first key are on
      #   # separate lines is indented one step (two spaces) more than the
      #   # position inside the opening parentheses.
      #
      #   # bad
      #   hash = {
      #     key: :value
      #   }
      #   and_in_a_method_call({
      #     no: :difference
      #                        })
      #   takes_multi_pairs_hash(x: {
      #     a: 1,
      #     b: 2
      #   },
      #                          y: {
      #                            c: 1,
      #                            d: 2
      #                          })
      #
      #   # good
      #   special_inside_parentheses
      #   hash = {
      #     key: :value
      #   }
      #   but_in_a_method_call({
      #                          its_like: :this
      #                        })
      #   takes_multi_pairs_hash(x: {
      #                            a: 1,
      #                            b: 2
      #                          },
      #                          y: {
      #                            c: 1,
      #                            d: 2
      #                          })
      #
      # @example EnforcedStyle: consistent
      #   # The `consistent` style enforces that the first key in a hash
      #   # literal where the opening brace and the first key are on
      #   # separate lines is indented the same as a hash literal which is not
      #   # defined inside a method call.
      #
      #   # bad
      #   hash = {
      #     key: :value
      #   }
      #   but_in_a_method_call({
      #                          its_like: :this
      #                         })
      #
      #   # good
      #   hash = {
      #     key: :value
      #   }
      #   and_in_a_method_call({
      #     no: :difference
      #   })
      #
      #
      # @example EnforcedStyle: align_braces
      #   # The `align_brackets` style enforces that the opening and closing
      #   # braces are indented to the same position.
      #
      #   # bad
      #   and_now_for_something = {
      #                             completely: :different
      #   }
      #   takes_multi_pairs_hash(x: {
      #     a: 1,
      #     b: 2
      #   },
      #                           y: {
      #                                c: 1,
      #                                d: 2
      #                              })
      #
      #   # good
      #   and_now_for_something = {
      #                             completely: :different
      #                           }
      #   takes_multi_pairs_hash(x: {
      #                               a: 1,
      #                               b: 2
      #                             },
      #                          y: {
      #                               c: 1,
      #                               d: 2
      #                             })
      class FirstHashElementIndentation < Base
        include Alignment
        include ConfigurableEnforcedStyle
        include MultilineElementIndentation
        extend AutoCorrector

        MSG = 'Use %<configured_indentation_width>d spaces for indentation ' \
              'in a hash, relative to %<base_description>s.'

        def on_hash(node)
          check(node, nil) if node.loc.begin
        end

        def on_send(node)
          return if enforce_first_argument_with_fixed_indentation?

          each_argument_node(node, :hash) do |hash_node, left_parenthesis|
            check(hash_node, left_parenthesis)
          end
        end
        alias on_csend on_send

        private

        def autocorrect(corrector, node)
          AlignmentCorrector.correct(corrector, processed_source, node, @column_delta)
        end

        def brace_alignment_style
          :align_braces
        end

        def check(hash_node, left_parenthesis)
          return if ignored_node?(hash_node)

          left_brace = hash_node.loc.begin
          first_pair = hash_node.pairs.first

          if first_pair
            return if same_line?(first_pair, left_brace)

            if separator_style?(first_pair)
              check_based_on_longest_key(hash_node, left_brace, left_parenthesis)
            else
              check_first(first_pair, left_brace, left_parenthesis, 0)
            end
          end

          check_right_brace(hash_node.loc.end, first_pair, left_brace, left_parenthesis)
        end

        def check_right_brace(right_brace, first_pair, left_brace, left_parenthesis)
          # if the right brace is on the same line as the last value, accept
          return if /\S/.match?(right_brace.source_line[0...right_brace.column])

          expected_column, indent_base_type = indent_base(left_brace, first_pair, left_parenthesis)
          @column_delta = expected_column - right_brace.column
          return if @column_delta.zero?

          message = message_for_right_brace(indent_base_type)
          add_offense(right_brace, message: message) do |corrector|
            autocorrect(corrector, right_brace)
          end
        end

        def separator_style?(first_pair)
          separator = first_pair.loc.operator
          key = "Enforced#{separator.is?(':') ? 'Colon' : 'HashRocket'}Style"
          config.for_cop('Layout/HashAlignment')[key] == 'separator'
        end

        def check_based_on_longest_key(hash_node, left_brace, left_parenthesis)
          key_lengths = hash_node.keys.map { |key| key.source_range.length }
          check_first(hash_node.pairs.first, left_brace, left_parenthesis,
                      key_lengths.max - key_lengths.first)
        end

        # Returns the description of what the correct indentation is based on.
        def base_description(indent_base_type)
          case indent_base_type
          when :left_brace_or_bracket
            'the position of the opening brace'
          when :first_column_after_left_parenthesis
            'the first position after the preceding left parenthesis'
          when :parent_hash_key
            'the parent hash key'
          else
            'the start of the line where the left curly brace is'
          end
        end

        def message(base_description)
          format(
            MSG,
            configured_indentation_width: configured_indentation_width,
            base_description: base_description
          )
        end

        def message_for_right_brace(indent_base_type)
          case indent_base_type
          when :left_brace_or_bracket
            'Indent the right brace the same as the left brace.'
          when :first_column_after_left_parenthesis
            'Indent the right brace the same as the first position ' \
            'after the preceding left parenthesis.'
          when :parent_hash_key
            'Indent the right brace the same as the parent hash key.'
          else
            'Indent the right brace the same as the start of the line ' \
            'where the left brace is.'
          end
        end

        def enforce_first_argument_with_fixed_indentation?
          argument_alignment_config = config.for_enabled_cop('Layout/ArgumentAlignment')
          argument_alignment_config['EnforcedStyle'] == 'with_fixed_indentation'
        end
      end
    end
  end
end
