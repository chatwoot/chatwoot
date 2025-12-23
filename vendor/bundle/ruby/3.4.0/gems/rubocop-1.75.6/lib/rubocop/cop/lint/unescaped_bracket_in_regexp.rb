# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for Regexpes (both literals and via `Regexp.new` / `Regexp.compile`)
      # that contain unescaped `]` characters.
      #
      # It emulates the following Ruby warning:
      #
      # [source,ruby]
      # ----
      # $ ruby -e '/abc]123/'
      # -e:1: warning: regular expression has ']' without escape: /abc]123/
      # ----
      #
      # @example
      #   # bad
      #   /abc]123/
      #   %r{abc]123}
      #   Regexp.new('abc]123')
      #   Regexp.compile('abc]123')
      #
      #   # good
      #   /abc\]123/
      #   %r{abc\]123}
      #   Regexp.new('abc\]123')
      #   Regexp.compile('abc\]123')
      #
      class UnescapedBracketInRegexp < Base
        extend AutoCorrector

        MSG = 'Regular expression has `]` without escape.'
        RESTRICT_ON_SEND = %i[new compile].freeze

        # @!method regexp_constructor(node)
        def_node_search :regexp_constructor, <<~PATTERN
          (send
            (const {nil? cbase} :Regexp) {:new :compile}
            $str
            ...
          )
        PATTERN

        def on_regexp(node)
          RuboCop::Util.silence_warnings do
            node.parsed_tree&.each_expression do |expr|
              detect_offenses(node, expr)
            end
          end
        end

        def on_send(node)
          # Ignore nodes that contain interpolation
          return if node.each_descendant(:dstr).any?

          regexp_constructor(node) do |text|
            parse_regexp(text.value)&.each_expression do |expr|
              detect_offenses(text, expr)
            end
          end
        end

        private

        def detect_offenses(node, expr)
          return unless expr.type?(:literal)

          expr.text.scan(/(?<!\\)\]/) do
            pos = Regexp.last_match.begin(0)
            next if pos.zero? # if the unescaped bracket is the first character, Ruby does not warn

            location = range_at_index(node, expr.ts, pos)

            add_offense(location) do |corrector|
              corrector.replace(location, '\]')
            end
          end
        end

        def range_at_index(node, index, offset)
          adjustment = index + offset
          node.loc.begin.end.adjust(begin_pos: adjustment, end_pos: adjustment + 1)
        end
      end
    end
  end
end
