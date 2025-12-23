# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for exact regexp match inside `Regexp` literals.
      #
      # @example
      #
      #   # bad
      #   string =~ /\Astring\z/
      #   string === /\Astring\z/
      #   string.match(/\Astring\z/)
      #   string.match?(/\Astring\z/)
      #
      #   # good
      #   string == 'string'
      #
      #   # bad
      #   string !~ /\Astring\z/
      #
      #   # good
      #   string != 'string'
      #
      class ExactRegexpMatch < Base
        extend AutoCorrector

        MSG = 'Use `%<prefer>s`.'
        RESTRICT_ON_SEND = %i[=~ === !~ match match?].freeze

        # @!method exact_regexp_match(node)
        def_node_matcher :exact_regexp_match, <<~PATTERN
          (call
            _ {:=~ :=== :!~ :match :match?}
            (regexp
              (str $_)
              (regopt)))
        PATTERN

        def on_send(node)
          return unless (receiver = node.receiver)
          return unless (regexp = exact_regexp_match(node))
          return unless (parsed_regexp = parse_regexp(regexp))
          return unless exact_match_pattern?(parsed_regexp)

          prefer = "#{receiver.source} #{new_method(node)} '#{parsed_regexp[1].text}'"

          add_offense(node, message: format(MSG, prefer: prefer)) do |corrector|
            corrector.replace(node, prefer)
          end
        end
        alias on_csend on_send

        private

        def exact_match_pattern?(parsed_regexp)
          tokens = parsed_regexp.map(&:token)
          return false unless tokens[0] == :bos && tokens[1] == :literal && tokens[2] == :eos

          !parsed_regexp[1].quantifier
        end

        def new_method(node)
          node.method?(:!~) ? '!=' : '=='
        end
      end
    end
  end
end
