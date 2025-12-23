# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks that reference brackets have or don't have
      # surrounding space depending on configuration.
      #
      # @example EnforcedStyle: no_space (default)
      #   # The `no_space` style enforces that reference brackets have
      #   # no surrounding space.
      #
      #   # bad
      #   hash[ :key ]
      #   array[ index ]
      #
      #   # good
      #   hash[:key]
      #   array[index]
      #
      # @example EnforcedStyle: space
      #   # The `space` style enforces that reference brackets have
      #   # surrounding space.
      #
      #   # bad
      #   hash[:key]
      #   array[index]
      #
      #   # good
      #   hash[ :key ]
      #   array[ index ]
      #
      #
      # @example EnforcedStyleForEmptyBrackets: no_space (default)
      #   # The `no_space` EnforcedStyleForEmptyBrackets style enforces that
      #   # empty reference brackets do not contain spaces.
      #
      #   # bad
      #   foo[ ]
      #   foo[     ]
      #   foo[
      #   ]
      #
      #   # good
      #   foo[]
      #
      # @example EnforcedStyleForEmptyBrackets: space
      #   # The `space` EnforcedStyleForEmptyBrackets style enforces that
      #   # empty reference brackets contain exactly one space.
      #
      #   # bad
      #   foo[]
      #   foo[    ]
      #   foo[
      #   ]
      #
      #   # good
      #   foo[ ]
      #
      class SpaceInsideReferenceBrackets < Base
        include SurroundingSpace
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        MSG = '%<command>s space inside reference brackets.'
        EMPTY_MSG = '%<command>s space inside empty reference brackets.'

        RESTRICT_ON_SEND = %i[[] []=].freeze

        def on_send(node)
          tokens = processed_source.tokens_within(node)
          left_token = left_ref_bracket(node, tokens)
          return unless left_token

          right_token = closing_bracket(tokens, left_token)

          if empty_brackets?(left_token, right_token, tokens: tokens)
            return empty_offenses(node, left_token, right_token, EMPTY_MSG)
          end

          return if node.multiline?

          if style == :no_space
            no_space_offenses(node, left_token, right_token, MSG)
          else
            space_offenses(node, left_token, right_token, MSG)
          end
        end

        private

        def autocorrect(corrector, node)
          tokens, left, right = reference_brackets(node)

          if empty_brackets?(left, right, tokens: tokens)
            SpaceCorrector.empty_corrections(processed_source, corrector, empty_config, left, right)
          elsif style == :no_space
            SpaceCorrector.remove_space(processed_source, corrector, left, right)
          else
            SpaceCorrector.add_space(processed_source, corrector, left, right)
          end
        end

        def reference_brackets(node)
          tokens = processed_source.tokens_within(node)
          left = left_ref_bracket(node, tokens)
          [tokens, left, closing_bracket(tokens, left)]
        end

        def left_ref_bracket(node, tokens)
          current_token = tokens.reverse.find(&:left_ref_bracket?)
          previous_token = previous_token(current_token)

          if node.method?(:[]=) || (previous_token && !previous_token.right_bracket?)
            tokens.find(&:left_ref_bracket?)
          else
            current_token
          end
        end

        def closing_bracket(tokens, opening_bracket)
          i = tokens.index(opening_bracket)
          inner_left_brackets_needing_closure = 0

          tokens[i..].each do |token|
            inner_left_brackets_needing_closure += 1 if token.left_bracket?
            inner_left_brackets_needing_closure -= 1 if token.right_bracket?
            return token if inner_left_brackets_needing_closure.zero? && token.right_bracket?
          end
        end

        def previous_token(current_token)
          index = processed_source.tokens.index(current_token)
          index.nil? || index.zero? ? nil : processed_source.tokens[index - 1]
        end

        def empty_config
          cop_config['EnforcedStyleForEmptyBrackets']
        end
      end
    end
  end
end
