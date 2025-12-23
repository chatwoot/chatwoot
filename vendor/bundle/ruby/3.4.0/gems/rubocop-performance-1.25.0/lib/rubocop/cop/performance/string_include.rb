# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Identifies unnecessary use of a regex where `String#include?` would suffice.
      #
      # @safety
      #   This cop's offenses are not safe to autocorrect if a receiver is nil or a Symbol.
      #
      # @example
      #   # bad
      #   str.match?(/ab/)
      #   /ab/.match?(str)
      #   str =~ /ab/
      #   /ab/ =~ str
      #   str.match(/ab/)
      #   /ab/.match(str)
      #   /ab/ === str
      #
      #   # good
      #   str.include?('ab')
      class StringInclude < Base
        extend AutoCorrector

        MSG = 'Use `%<negation>sString#include?` instead of a regex match with literal-only pattern.'
        RESTRICT_ON_SEND = %i[match =~ !~ match? ===].freeze

        def_node_matcher :redundant_regex?, <<~PATTERN
          {(call $!nil? {:match :=~ :!~ :match?} (regexp (str $#literal?) (regopt)))
           (send (regexp (str $#literal?) (regopt)) {:match :match? :===} $_)
           (match-with-lvasgn (regexp (str $#literal?) (regopt)) $_)
           (send (regexp (str $#literal?) (regopt)) :=~ $_)}
        PATTERN

        # rubocop:disable Metrics/AbcSize
        def on_send(node)
          return unless (receiver, regex_str = redundant_regex?(node))

          negation = node.send_type? && node.method?(:!~)
          message = format(MSG, negation: ('!' if negation))

          add_offense(node, message: message) do |corrector|
            receiver, regex_str = regex_str, receiver if receiver.is_a?(String)
            regex_str = interpret_string_escapes(regex_str)
            dot = node.loc.dot ? node.loc.dot.source : '.'

            new_source = "#{'!' if negation}#{receiver.source}#{dot}include?(#{to_string_literal(regex_str)})"

            corrector.replace(node, new_source)
          end
        end
        # rubocop:enable Metrics/AbcSize
        alias on_csend on_send
        alias on_match_with_lvasgn on_send

        private

        def literal?(regex_str)
          regex_str.match?(/\A#{Util::LITERAL_REGEX}+\z/o)
        end
      end
    end
  end
end
