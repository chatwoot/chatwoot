# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Identifies unnecessary use of a regex where `String#end_with?` would suffice.
      #
      # This cop has `SafeMultiline` configuration option that `true` by default because
      # `end$` is unsafe as it will behave incompatible with `end_with?`
      # for receiver is multiline string.
      #
      # @safety
      #   This will change to a new method call which isn't guaranteed to be on the
      #   object. Switching these methods has to be done with knowledge of the types
      #   of the variables which rubocop doesn't have.
      #
      # @example
      #   # bad
      #   'abc'.match?(/bc\Z/)
      #   /bc\Z/.match?('abc')
      #   'abc' =~ /bc\Z/
      #   /bc\Z/ =~ 'abc'
      #   'abc'.match(/bc\Z/)
      #   /bc\Z/.match('abc')
      #
      #   # good
      #   'abc'.end_with?('bc')
      #
      # @example SafeMultiline: true (default)
      #
      #   # good
      #   'abc'.match?(/bc$/)
      #   /bc$/.match?('abc')
      #   'abc' =~ /bc$/
      #   /bc$/ =~ 'abc'
      #   'abc'.match(/bc$/)
      #   /bc$/.match('abc')
      #
      # @example SafeMultiline: false
      #
      #   # bad
      #   'abc'.match?(/bc$/)
      #   /bc$/.match?('abc')
      #   'abc' =~ /bc$/
      #   /bc$/ =~ 'abc'
      #   'abc'.match(/bc$/)
      #   /bc$/.match('abc')
      #
      class EndWith < Base
        include RegexpMetacharacter
        extend AutoCorrector

        MSG = 'Use `String#end_with?` instead of a regex match anchored to the end of the string.'
        RESTRICT_ON_SEND = %i[match =~ match?].freeze

        def_node_matcher :redundant_regex?, <<~PATTERN
          {(call $!nil? {:match :=~ :match?} (regexp (str $#literal_at_end?) (regopt)))
           (send (regexp (str $#literal_at_end?) (regopt)) {:match :match?} $_)
           ({send match-with-lvasgn} (regexp (str $#literal_at_end?) (regopt)) $_)
           (send (regexp (str $#literal_at_end?) (regopt)) :=~ $_)}
        PATTERN

        def on_send(node)
          return unless (receiver, regex_str = redundant_regex?(node))

          add_offense(node) do |corrector|
            receiver, regex_str = regex_str, receiver if receiver.is_a?(String)
            regex_str = drop_end_metacharacter(regex_str)
            regex_str = interpret_string_escapes(regex_str)
            dot = node.loc.dot ? node.loc.dot.source : '.'

            new_source = "#{receiver.source}#{dot}end_with?(#{to_string_literal(regex_str)})"

            corrector.replace(node, new_source)
          end
        end
        alias on_csend on_send
        alias on_match_with_lvasgn on_send
      end
    end
  end
end
