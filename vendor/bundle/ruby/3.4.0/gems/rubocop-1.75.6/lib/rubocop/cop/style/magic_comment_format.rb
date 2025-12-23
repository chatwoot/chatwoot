# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Ensures magic comments are written consistently throughout your code base.
      # Looks for discrepancies in separators (`-` vs `_`) and capitalization for
      # both magic comment directives and values.
      #
      # Required capitalization can be set with the `DirectiveCapitalization` and
      # `ValueCapitalization` configuration keys.
      #
      # NOTE: If one of these configuration is set to nil, any capitalization is allowed.
      #
      # @example EnforcedStyle: snake_case (default)
      #   # The `snake_case` style will enforce that the frozen string literal
      #   # comment is written in snake case. (Words separated by underscores)
      #   # bad
      #   # frozen-string-literal: true
      #
      #   module Bar
      #     # ...
      #   end
      #
      #   # good
      #   # frozen_string_literal: false
      #
      #   module Bar
      #     # ...
      #   end
      #
      # @example EnforcedStyle: kebab_case
      #   # The `kebab_case` style will enforce that the frozen string literal
      #   # comment is written in kebab case. (Words separated by hyphens)
      #   # bad
      #   # frozen_string_literal: true
      #
      #   module Baz
      #     # ...
      #   end
      #
      #   # good
      #   # frozen-string-literal: true
      #
      #   module Baz
      #     # ...
      #   end
      #
      # @example DirectiveCapitalization: lowercase (default)
      #   # bad
      #   # FROZEN-STRING-LITERAL: true
      #
      #   # good
      #   # frozen-string-literal: true
      #
      # @example DirectiveCapitalization: uppercase
      #   # bad
      #   # frozen-string-literal: true
      #
      #   # good
      #   # FROZEN-STRING-LITERAL: true
      #
      # @example DirectiveCapitalization: nil
      #   # any capitalization is accepted
      #
      #   # good
      #   # frozen-string-literal: true
      #
      #   # good
      #   # FROZEN-STRING-LITERAL: true
      #
      # @example ValueCapitalization: nil (default)
      #   # any capitalization is accepted
      #
      #   # good
      #   # frozen-string-literal: true
      #
      #   # good
      #   # frozen-string-literal: TRUE
      #
      # @example ValueCapitalization: lowercase
      #   # when a value is not given, any capitalization is accepted
      #
      #   # bad
      #   # frozen-string-literal: TRUE
      #
      #   # good
      #   # frozen-string-literal: TRUE
      #
      # @example ValueCapitalization: uppercase
      #   # bad
      #   # frozen-string-literal: true
      #
      #   # good
      #   # frozen-string-literal: TRUE
      #
      class MagicCommentFormat < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        SNAKE_SEPARATOR = '_'
        KEBAB_SEPARATOR = '-'
        MSG = 'Prefer %<style>s case for magic comments.'
        MSG_VALUE = 'Prefer %<case>s for magic comment values.'

        # Value object to extract source ranges for the different parts of a magic comment
        class CommentRange
          extend SimpleForwardable

          DIRECTIVE_REGEXP = Regexp.union(MagicComment::KEYWORDS.map do |_, v|
            Regexp.new(v, Regexp::IGNORECASE)
          end).freeze

          VALUE_REGEXP = Regexp.new("(?:#{DIRECTIVE_REGEXP}:\s*)(.*?)(?=;|$)")

          def_delegators :@comment, :text, :loc
          attr_reader :comment

          def initialize(comment)
            @comment = comment
          end

          # A magic comment can contain one directive (normal style) or
          # multiple directives (emacs style)
          def directives
            @directives ||= begin
              matches = []

              text.scan(DIRECTIVE_REGEXP) do
                offset = Regexp.last_match.offset(0)
                matches << loc.expression.adjust(begin_pos: offset.first)
                              .with(end_pos: loc.expression.begin_pos + offset.last)
              end

              matches
            end
          end

          # A magic comment can contain one value (normal style) or
          # multiple directives (emacs style)
          def values
            @values ||= begin
              matches = []

              text.scan(VALUE_REGEXP) do
                offset = Regexp.last_match.offset(1)
                matches << loc.expression.adjust(begin_pos: offset.first)
                              .with(end_pos: loc.expression.begin_pos + offset.last)
              end

              matches
            end
          end
        end

        def on_new_investigation
          return unless processed_source.ast

          magic_comments.each do |comment|
            issues = find_issues(comment)
            register_offenses(issues) if issues.any?
          end
        end

        private

        def magic_comments
          processed_source.each_comment_in_lines(leading_comment_lines)
                          .select { |comment| MagicComment.parse(comment.text).valid? }
                          .map { |comment| CommentRange.new(comment) }
        end

        def leading_comment_lines
          first_non_comment_token = processed_source.tokens.find { |token| !token.comment? }

          if first_non_comment_token
            0...first_non_comment_token.line
          else
            (0..)
          end
        end

        def find_issues(comment)
          issues = { directives: [], values: [] }

          comment.directives.each do |directive|
            issues[:directives] << directive if directive_offends?(directive)
          end

          comment.values.each do |value| # rubocop:disable Style/HashEachMethods
            issues[:values] << value if wrong_capitalization?(value.source, value_capitalization)
          end

          issues
        end

        def directive_offends?(directive)
          incorrect_separator?(directive.source) ||
            wrong_capitalization?(directive.source, directive_capitalization)
        end

        def register_offenses(issues)
          fix_directives(issues[:directives])
          fix_values(issues[:values])
        end

        def fix_directives(issues)
          return if issues.empty?

          msg = format(MSG, style: expected_style)

          issues.each do |directive|
            add_offense(directive, message: msg) do |corrector|
              replacement = replace_separator(replace_capitalization(directive.source,
                                                                     directive_capitalization))
              corrector.replace(directive, replacement)
            end
          end
        end

        def fix_values(issues)
          return if issues.empty?

          msg = format(MSG_VALUE, case: value_capitalization)

          issues.each do |value|
            add_offense(value, message: msg) do |corrector|
              corrector.replace(value, replace_capitalization(value.source, value_capitalization))
            end
          end
        end

        def expected_style
          [directive_capitalization, style].compact.join(' ').gsub(/_?case\b/, '')
        end

        def wrong_separator
          style == :snake_case ? KEBAB_SEPARATOR : SNAKE_SEPARATOR
        end

        def correct_separator
          style == :snake_case ? SNAKE_SEPARATOR : KEBAB_SEPARATOR
        end

        def incorrect_separator?(text)
          text[wrong_separator]
        end

        def wrong_capitalization?(text, expected_case)
          return false unless expected_case

          case expected_case
          when :lowercase
            text != text.downcase
          when :uppercase
            text != text.upcase
          end
        end

        def replace_separator(text)
          text.tr(wrong_separator, correct_separator)
        end

        def replace_capitalization(text, style)
          return text unless style

          case style
          when :lowercase
            text.downcase
          when :uppercase
            text.upcase
          end
        end

        def line_range(line)
          processed_source.buffer.line_range(line)
        end

        def directive_capitalization
          cop_config['DirectiveCapitalization']&.to_sym.tap do |style|
            unless valid_capitalization?(style)
              raise "Unknown `DirectiveCapitalization` #{style} selected!"
            end
          end
        end

        def value_capitalization
          cop_config['ValueCapitalization']&.to_sym.tap do |style|
            unless valid_capitalization?(style)
              raise "Unknown `ValueCapitalization` #{style} selected!"
            end
          end
        end

        def valid_capitalization?(style)
          return true unless style

          supported_capitalizations.include?(style)
        end

        def supported_capitalizations
          cop_config['SupportedCapitalizations'].map(&:to_sym)
        end
      end
    end
  end
end
