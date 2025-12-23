# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Identifies places where a case-insensitive string comparison
      # can better be implemented using `casecmp`.
      #
      # This cop is disabled by default because `String#casecmp` only works with
      # ASCII characters. See https://github.com/rubocop/rubocop/issues/9753.
      #
      # If you are working only with ASCII characters, then this cop can be
      # safely enabled.
      #
      # @safety
      #   This cop is unsafe because `String#casecmp` and `String#casecmp?` behave
      #   differently when using Non-ASCII characters.
      #
      # @example
      #   # bad
      #   str.downcase == 'abc'
      #   str.upcase.eql? 'ABC'
      #   'abc' == str.downcase
      #   'ABC'.eql? str.upcase
      #   str.downcase == str.downcase
      #
      #   # good
      #   str.casecmp('ABC').zero?
      #   'abc'.casecmp(str).zero?
      class Casecmp < Base
        extend AutoCorrector

        MSG = 'Use `%<good>s` instead of `%<bad>s`.'
        RESTRICT_ON_SEND = %i[== eql? !=].freeze
        CASE_METHODS = %i[downcase upcase].freeze

        def_node_matcher :downcase_eq, <<~PATTERN
          (send
            $(send _ ${:downcase :upcase})
            ${:== :eql? :!=}
            ${str (send _ {:downcase :upcase} ...) (begin str)})
        PATTERN

        def_node_matcher :eq_downcase, <<~PATTERN
          (send
            {str (send _ {:downcase :upcase} ...) (begin str)}
            ${:== :eql? :!=}
            $(send _ ${:downcase :upcase}))
        PATTERN

        def_node_matcher :downcase_downcase, <<~PATTERN
          (send
            $(send _ ${:downcase :upcase})
            ${:== :eql? :!=}
            $(send _ ${:downcase :upcase}))
        PATTERN

        def on_send(node)
          return unless downcase_eq(node) || eq_downcase(node)
          return unless (parts = take_method_apart(node))

          _receiver, method, arg, variable = parts
          good_method = build_good_method(method, arg, variable)

          message = format(MSG, good: good_method, bad: node.source)
          add_offense(node, message: message) do |corrector|
            autocorrect(corrector, node, good_method)
          end
        end

        private

        def take_method_apart(node)
          if downcase_downcase(node)
            receiver, method, rhs = *node
            arg, = *rhs
          elsif downcase_eq(node)
            receiver, method, arg = *node
          elsif eq_downcase(node)
            arg, method, receiver = *node
          else
            return
          end

          variable, = *receiver

          [receiver, method, arg, variable]
        end

        def autocorrect(corrector, node, replacement)
          corrector.replace(node, replacement)
        end

        def build_good_method(method, arg, variable)
          bang = method == :!= ? '!' : ''

          # We want resulting call to be parenthesized
          # if arg already includes one or more sets of parens, don't add more
          # or if method call already used parens, again, don't add more
          if arg.send_type? || !parentheses?(arg)
            "#{bang}#{variable.source}.casecmp(#{arg.source}).zero?"
          else
            "#{bang}#{variable.source}.casecmp#{arg.source}.zero?"
          end
        end
      end
    end
  end
end
