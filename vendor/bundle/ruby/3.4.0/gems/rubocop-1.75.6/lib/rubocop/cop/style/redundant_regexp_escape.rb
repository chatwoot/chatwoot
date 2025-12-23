# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for redundant escapes inside `Regexp` literals.
      #
      # @example
      #   # bad
      #   %r{foo\/bar}
      #
      #   # good
      #   %r{foo/bar}
      #
      #   # good
      #   /foo\/bar/
      #
      #   # good
      #   %r/foo\/bar/
      #
      #   # good
      #   %r!foo\!bar!
      #
      #   # bad
      #   /a\-b/
      #
      #   # good
      #   /a-b/
      #
      #   # bad
      #   /[\+\-]\d/
      #
      #   # good
      #   /[+\-]\d/
      class RedundantRegexpEscape < Base
        include RangeHelp
        extend AutoCorrector

        MSG_REDUNDANT_ESCAPE = 'Redundant escape inside regexp literal'

        ALLOWED_ALWAYS_ESCAPES = " \n[]^\\#".chars.freeze
        ALLOWED_WITHIN_CHAR_CLASS_METACHAR_ESCAPES = '-'.chars.freeze
        ALLOWED_OUTSIDE_CHAR_CLASS_METACHAR_ESCAPES = '.*+?{}()|$'.chars.freeze

        def on_regexp(node)
          each_escape(node) do |char, index, within_character_class|
            next if char.valid_encoding? && allowed_escape?(node, char, index,
                                                            within_character_class)

            location = escape_range_at_index(node, index)

            add_offense(location, message: MSG_REDUNDANT_ESCAPE) do |corrector|
              corrector.remove_leading(escape_range_at_index(node, index), 1)
            end
          end
        end

        private

        def allowed_escape?(node, char, index, within_character_class)
          # Strictly speaking a few single-letter metachars are currently
          # unnecessary to "escape", e.g. i, E, F, but enumerating them is
          # rather difficult, and their behavior could change over time with
          # different versions of Ruby so that e.g. /\i/ != /i/
          return true if /[[:alnum:]]/.match?(char)
          return true if ALLOWED_ALWAYS_ESCAPES.include?(char) || delimiter?(node, char)

          if within_character_class
            ALLOWED_WITHIN_CHAR_CLASS_METACHAR_ESCAPES.include?(char) &&
              !char_class_begins_or_ends_with_escaped_hyphen?(node, index)
          else
            ALLOWED_OUTSIDE_CHAR_CLASS_METACHAR_ESCAPES.include?(char)
          end
        end

        def char_class_begins_or_ends_with_escaped_hyphen?(node, index)
          # The hyphen character is allowed to be escaped within a character class
          # but it's not necessary to escape hyphen if it's the first or last character
          # within the character class. This method checks if that's the case.
          # e.g. "[0-9\\-]" or "[\\-0-9]" would return true
          content = contents_range(node).source

          if content[index + 2] == ']'
            true
          elsif content[index - 1] == '['
            index < 2 || content[index - 2] != '\\'
          else
            false
          end
        end

        def delimiter?(node, char)
          delimiters = [node.loc.begin.source[-1], node.loc.end.source[0]]

          delimiters.include?(char)
        end

        def each_escape(node)
          node.parsed_tree&.traverse&.reduce(0) do |char_class_depth, (event, expr)|
            yield(expr.text[1], expr.ts, !char_class_depth.zero?) if expr.type == :escape

            if expr.type == :set
              char_class_depth + (event == :enter ? 1 : -1)
            else
              char_class_depth
            end
          end
        end

        def escape_range_at_index(node, index)
          regexp_begin = node.loc.begin.end_pos

          start = regexp_begin + index

          range_between(start, start + 2)
        end
      end
    end
  end
end
