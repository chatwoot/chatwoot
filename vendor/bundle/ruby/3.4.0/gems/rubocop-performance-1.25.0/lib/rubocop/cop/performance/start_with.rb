# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Identifies unnecessary use of a regex where `String#start_with?` would suffice.
      #
      # This cop has `SafeMultiline` configuration option that `true` by default because
      # `^start` is unsafe as it will behave incompatible with `start_with?`
      # for receiver is multiline string.
      #
      # @safety
      #   This will change to a new method call which isn't guaranteed to be on the
      #   object. Switching these methods has to be done with knowledge of the types
      #   of the variables which rubocop doesn't have.
      #
      # @example
      #   # bad
      #   'abc'.match?(/\Aab/)
      #   /\Aab/.match?('abc')
      #   'abc' =~ /\Aab/
      #   /\Aab/ =~ 'abc'
      #   'abc'.match(/\Aab/)
      #   /\Aab/.match('abc')
      #
      #   # good
      #   'abc'.start_with?('ab')
      #
      # @example SafeMultiline: true (default)
      #
      #   # good
      #   'abc'.match?(/^ab/)
      #   /^ab/.match?('abc')
      #   'abc' =~ /^ab/
      #   /^ab/ =~ 'abc'
      #   'abc'.match(/^ab/)
      #   /^ab/.match('abc')
      #
      # @example SafeMultiline: false
      #
      #   # bad
      #   'abc'.match?(/^ab/)
      #   /^ab/.match?('abc')
      #   'abc' =~ /^ab/
      #   /^ab/ =~ 'abc'
      #   'abc'.match(/^ab/)
      #   /^ab/.match('abc')
      #
      class StartWith < Base
        include RegexpMetacharacter
        extend AutoCorrector

        MSG = 'Use `String#start_with?` instead of a regex match anchored to the beginning of the string.'
        RESTRICT_ON_SEND = %i[match =~ match?].freeze

        def_node_matcher :redundant_regex?, <<~PATTERN
          {(call $!nil? {:match :=~ :match?} (regexp (str $#literal_at_start?) (regopt)))
           (send (regexp (str $#literal_at_start?) (regopt)) {:match :match?} $_)
           (match-with-lvasgn (regexp (str $#literal_at_start?) (regopt)) $_)
           (send (regexp (str $#literal_at_start?) (regopt)) :=~ $_)}
        PATTERN

        def on_send(node)
          return unless (receiver, regex_str = redundant_regex?(node))

          add_offense(node) do |corrector|
            receiver, regex_str = regex_str, receiver if receiver.is_a?(String)
            regex_str = drop_start_metacharacter(regex_str)
            regex_str = interpret_string_escapes(regex_str)
            dot = node.loc.dot ? node.loc.dot.source : '.'

            new_source = "#{receiver.source}#{dot}start_with?(#{to_string_literal(regex_str)})"

            corrector.replace(node, new_source)
          end
        end
        alias on_csend on_send
        alias on_match_with_lvasgn on_send
      end
    end
  end
end
