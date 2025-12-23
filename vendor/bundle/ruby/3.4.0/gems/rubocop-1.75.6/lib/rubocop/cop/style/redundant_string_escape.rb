# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for redundant escapes in string literals.
      #
      # @example
      #   # bad - no need to escape # without following {/$/@
      #   "\#foo"
      #
      #   # bad - no need to escape single quotes inside double quoted string
      #   "\'foo\'"
      #
      #   # bad - heredocs are also checked for unnecessary escapes
      #   <<~STR
      #     \#foo \"foo\"
      #   STR
      #
      #   # good
      #   "#foo"
      #
      #   # good
      #   "\#{no_interpolation}"
      #
      #   # good
      #   "'foo'"
      #
      #   # good
      #   "foo\
      #   bar"
      #
      #   # good
      #   <<~STR
      #     #foo "foo"
      #   STR
      class RedundantStringEscape < Base
        include MatchRange
        extend AutoCorrector

        MSG = 'Redundant escape of %<char>s inside string literal.'

        def on_str(node)
          return if node.parent&.type?(:regexp, :xstr) || node.character_literal?

          str_contents_range = str_contents_range(node)

          each_match_range(str_contents_range, /(\\.)/) do |range|
            next if allowed_escape?(node, range.resize(3))

            add_offense(range) do |corrector|
              corrector.remove_leading(range, 1)
            end
          end
        end

        private

        def message(range)
          format(MSG, char: range.source[-1])
        end

        def str_contents_range(node)
          if heredoc?(node)
            node.loc.heredoc_body
          elsif node.str_type?
            node.source_range
          elsif begin_loc_present?(node)
            contents_range(node)
          end
        end

        def begin_loc_present?(node)
          # e.g. a __FILE__ literal has no begin loc so we can't query if it's nil
          node.loc.to_hash.key?(:begin) && !node.loc.begin.nil?
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        def allowed_escape?(node, range)
          escaped = range.source[(1..-1)]

          # Inside a single-quoted string, escapes (except \\ and \') do not have special meaning,
          # and so are not redundant, as they are a literal backslash.
          return true if interpolation_not_enabled?(node)

          # Strictly speaking a few single-letter chars are currently unnecessary to "escape", e.g.
          # d, but enumerating them is rather difficult, and their behavior could change over time
          # with different versions of Ruby so that e.g. /\d/ != /d/
          return true if /[\n\\[[:alnum:]]]/.match?(escaped[0])

          return true if escaped[0] == ' ' && (percent_array_literal?(node) || node.heredoc?)

          return true if disabling_interpolation?(range)
          return true if delimiter?(node, escaped[0])

          false
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        def interpolation_not_enabled?(node)
          single_quoted?(node) ||
            percent_w_literal?(node) ||
            percent_q_literal?(node) ||
            heredoc_with_disabled_interpolation?(node)
        end

        def single_quoted?(node)
          delimiter?(node, "'")
        end

        def percent_q_literal?(node)
          if literal_in_interpolated_or_multiline_string?(node)
            percent_q_literal?(node.parent)
          else
            node.source.start_with?('%q')
          end
        end

        def array_literal?(node, prefix)
          if literal_in_interpolated_or_multiline_string?(node)
            array_literal?(node.parent, prefix)
          else
            node.parent&.array_type? && node.parent.source.start_with?(prefix)
          end
        end

        def percent_w_literal?(node)
          array_literal?(node, '%w')
        end

        def percent_w_upper_literal?(node)
          array_literal?(node, '%W')
        end

        def percent_array_literal?(node)
          percent_w_literal?(node) || percent_w_upper_literal?(node)
        end

        def heredoc_with_disabled_interpolation?(node)
          if heredoc?(node)
            node.source.end_with?("'")
          elsif node.parent&.dstr_type?
            heredoc_with_disabled_interpolation?(node.parent)
          else
            false
          end
        end

        def heredoc?(node)
          node.type?(:str, :dstr) && node.heredoc?
        end

        def delimiter?(node, char)
          return false if heredoc?(node)

          if literal_in_interpolated_or_multiline_string?(node) || percent_array_literal?(node)
            return delimiter?(node.parent, char)
          end

          return true unless node.loc.begin

          delimiters = [node.loc.begin.source[-1], node.loc.end.source[0]]

          delimiters.include?(char)
        end

        def literal_in_interpolated_or_multiline_string?(node)
          node.str_type? && !begin_loc_present?(node) && node.parent&.dstr_type?
        end

        def disabling_interpolation?(range)
          # Allow \#{foo}, \#$foo, \#@foo, and \#@@foo
          # for escaping local, global, instance and class variable interpolations
          return true if range.source.match?(/\A\\#[{$@]/)
          # Also allow #\{foo}, #\$foo, #\@foo and #\@@foo
          return true if range.adjust(begin_pos: -2).source.match?(/\A[^\\]#\\[{$@]/)
          # For `\#\{foo} allow `\#` and warn `\{`
          return true if range.adjust(end_pos: 1).source == '\\#\\{'

          false
        end
      end
    end
  end
end
