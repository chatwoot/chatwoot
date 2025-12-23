# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for handling regexp metacharacters.
    module RegexpMetacharacter
      private

      def literal_at_start?(regexp)
        return true if literal_at_start_with_backslash_a?(regexp)

        !safe_multiline? && literal_at_start_with_caret?(regexp)
      end

      def literal_at_end?(regexp)
        return true if literal_at_end_with_backslash_z?(regexp)

        !safe_multiline? && literal_at_end_with_dollar?(regexp)
      end

      def literal_at_start_with_backslash_a?(regex_str)
        # is this regexp 'literal' in the sense of only matching literal
        # chars, rather than using metachars like `.` and `*` and so on?
        # also, is it anchored at the start of the string?
        # (tricky: \s, \d, and so on are metacharacters, but other characters
        #  escaped with a slash are just literals. LITERAL_REGEX takes all
        #  that into account.)
        /\A\\A(?:#{Util::LITERAL_REGEX})+\z/o.match?(regex_str)
      end

      def literal_at_start_with_caret?(regex_str)
        # is this regexp 'literal' in the sense of only matching literal
        # chars, rather than using metachars like `.` and `*` and so on?
        # also, is it anchored at the start of the string?
        # (tricky: \s, \d, and so on are metacharacters, but other characters
        #  escaped with a slash are just literals. LITERAL_REGEX takes all
        #  that into account.)
        /\A\^(?:#{Util::LITERAL_REGEX})+\z/o.match?(regex_str)
      end

      def literal_at_end_with_backslash_z?(regex_str)
        # is this regexp 'literal' in the sense of only matching literal
        # chars, rather than using metachars like . and * and so on?
        # also, is it anchored at the end of the string?
        /\A(?:#{Util::LITERAL_REGEX})+\\z\z/o.match?(regex_str)
      end

      def literal_at_end_with_dollar?(regex_str)
        # is this regexp 'literal' in the sense of only matching literal
        # chars, rather than using metachars like . and * and so on?
        # also, is it anchored at the end of the string?
        /\A(?:#{Util::LITERAL_REGEX})+\$\z/o.match?(regex_str)
      end

      def drop_start_metacharacter(regexp_string)
        if regexp_string.start_with?('\\A')
          regexp_string[2..] # drop `\A` anchor
        else
          regexp_string[1..] # drop `^` anchor
        end
      end

      def drop_end_metacharacter(regexp_string)
        if regexp_string.end_with?('\\z')
          regexp_string.chomp('\z') # drop `\z` anchor
        else
          regexp_string.chop # drop `$` anchor
        end
      end

      def safe_multiline?
        cop_config.fetch('SafeMultiline', true)
      end
    end
  end
end
