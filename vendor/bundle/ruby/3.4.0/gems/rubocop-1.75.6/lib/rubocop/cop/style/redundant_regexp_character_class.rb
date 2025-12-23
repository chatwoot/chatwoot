# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for unnecessary single-element `Regexp` character classes.
      #
      # @example
      #
      #   # bad
      #   r = /[x]/
      #
      #   # good
      #   r = /x/
      #
      #   # bad
      #   r = /[\s]/
      #
      #   # good
      #   r = /\s/
      #
      #   # bad
      #   r = %r{/[b]}
      #
      #   # good
      #   r = %r{/b}
      #
      #   # good
      #   r = /[ab]/
      class RedundantRegexpCharacterClass < Base
        extend AutoCorrector

        REQUIRES_ESCAPE_OUTSIDE_CHAR_CLASS_CHARS = '.*+?{}()|$'.chars.freeze
        MSG_REDUNDANT_CHARACTER_CLASS = 'Redundant single-element character class, ' \
                                        '`%<char_class>s` can be replaced with `%<element>s`.'

        def on_regexp(node)
          each_redundant_character_class(node) do |loc|
            add_offense(
              loc, message: format(
                MSG_REDUNDANT_CHARACTER_CLASS,
                char_class: loc.source,
                element: without_character_class(loc)
              )
            ) do |corrector|
              corrector.replace(loc, without_character_class(loc))
            end
          end
        end

        private

        def each_redundant_character_class(node)
          each_single_element_character_class(node) do |char_class|
            next unless redundant_single_element_character_class?(node, char_class)

            yield char_class.loc.body
          end
        end

        def each_single_element_character_class(node)
          node.parsed_tree&.each_expression do |expr|
            next if expr.type != :set || expr.expressions.size != 1
            next if expr.negative?
            next if %i[set posixclass nonposixclass].include?(expr.expressions.first.type)
            next if multiple_codepoints?(expr.expressions.first)

            yield expr
          end
        end

        def redundant_single_element_character_class?(node, char_class)
          class_elem = char_class.expressions.first.text

          non_redundant =
            whitespace_in_free_space_mode?(node, class_elem) ||
            backslash_b?(class_elem) || octal_requiring_char_class?(class_elem) ||
            requires_escape_outside_char_class?(class_elem)

          !non_redundant
        end

        def multiple_codepoints?(expression)
          expression.respond_to?(:codepoints) && expression.codepoints.count >= 2
        end

        def without_character_class(loc)
          without_character_class = loc.source[1..-2]

          # Adds `\` to prevent autocorrection that changes to an interpolated string when `[#]`.
          # e.g. From `/[#]{0}/` to `/#{0}/`
          loc.source == '[#]' ? "\\#{without_character_class}" : without_character_class
        end

        def whitespace_in_free_space_mode?(node, elem)
          return false unless node.extended?

          /\s/.match?(elem)
        end

        def backslash_b?(elem)
          # \b's behavior is different inside and outside of a character class, matching word
          # boundaries outside but backspace (0x08) when inside.
          elem == '\b'
        end

        def octal_requiring_char_class?(elem)
          # The octal escapes \1 to \7 only work inside a character class
          # because they would be a backreference outside it.
          elem.match?(/\A\\[1-7]\z/)
        end

        def requires_escape_outside_char_class?(elem)
          REQUIRES_ESCAPE_OUTSIDE_CHAR_CLASS_CHARS.include?(elem)
        end
      end
    end
  end
end
