# frozen_string_literal: true

require_relative '../../directive_comment'

module RuboCop
  module Cop
    module Style
      # Checks for comments put on the same line as some keywords.
      # These keywords are: `class`, `module`, `def`, `begin`, `end`.
      #
      # Note that some comments
      # (`:nodoc:`, `:yields:`, `rubocop:disable` and `rubocop:todo`),
      # RBS::Inline annotation, and Steep annotation (`steep:ignore`) are allowed.
      #
      # Autocorrection removes comments from `end` keyword and keeps comments
      # for `class`, `module`, `def` and `begin` above the keyword.
      #
      # @safety
      #   Autocorrection is unsafe because it may remove a comment that is
      #   meaningful.
      #
      # @example
      #   # bad
      #   if condition
      #     statement
      #   end # end if
      #
      #   # bad
      #   class X # comment
      #     statement
      #   end
      #
      #   # bad
      #   def x; end # comment
      #
      #   # good
      #   if condition
      #     statement
      #   end
      #
      #   # good
      #   class X # :nodoc:
      #     y
      #   end
      class CommentedKeyword < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Do not place comments on the same line as the `%<keyword>s` keyword.'

        KEYWORDS = %w[begin class def end module].freeze
        KEYWORD_REGEXES = KEYWORDS.map { |w| /^\s*#{w}\s/ }.freeze

        ALLOWED_COMMENTS = %w[:nodoc: :yields:].freeze
        ALLOWED_COMMENT_REGEXES = (ALLOWED_COMMENTS.map { |c| /#\s*#{c}/ } +
                                   [DirectiveComment::DIRECTIVE_COMMENT_REGEXP]).freeze

        REGEXP = /(?<keyword>\S+).*#/.freeze

        SUBCLASS_DEFINITION = /\A\s*class\s+(\w|::)+\s*<\s*(\w|::)+/.freeze
        METHOD_OR_END_DEFINITIONS = /\A\s*(def\s|end)/.freeze

        STEEP_REGEXP = /#\ssteep:ignore(\s|\z)/.freeze

        def on_new_investigation
          processed_source.comments.each do |comment|
            next unless offensive?(comment) && (match = source_line(comment).match(REGEXP))

            register_offense(comment, match[:keyword])
          end
        end

        private

        def register_offense(comment, matched_keyword)
          add_offense(comment, message: format(MSG, keyword: matched_keyword)) do |corrector|
            range = range_with_surrounding_space(comment.source_range, newlines: false)
            corrector.remove(range)

            unless matched_keyword == 'end'
              corrector.insert_before(
                range.source_buffer.line_range(comment.loc.line), "#{comment.text}\n"
              )
            end
          end
        end

        def offensive?(comment)
          line = source_line(comment)
          return false if rbs_inline_annotation?(line, comment)
          return false if steep_annotation?(comment)

          KEYWORD_REGEXES.any? { |r| r.match?(line) } &&
            ALLOWED_COMMENT_REGEXES.none? { |r| r.match?(line) }
        end

        def source_line(comment)
          comment.source_range.source_line
        end

        def rbs_inline_annotation?(line, comment)
          case line
          when SUBCLASS_DEFINITION
            comment.text.start_with?(/#\[.+\]/)
          when METHOD_OR_END_DEFINITIONS
            comment.text.start_with?('#:')
          else
            false
          end
        end

        def steep_annotation?(comment)
          comment.text.match?(STEEP_REGEXP)
        end
      end
    end
  end
end
