# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Identifies the use of `Regexp#match` or `String#match`, which
      # returns `#<MatchData>`/`nil`. The return value of `=~` is an integral
      # index/`nil` and is more performant.
      #
      # @example
      #   # bad
      #   do_something if str.match(/regex/)
      #   while regex.match('str')
      #     do_something
      #   end
      #
      #   # good
      #   method(str =~ /regex/)
      #   return value unless regex =~ 'str'
      class RedundantMatch < Base
        extend AutoCorrector

        MSG = 'Use `=~` in places where the `MatchData` returned by `#match` will not be used.'
        RESTRICT_ON_SEND = %i[match].freeze

        HIGHER_PRECEDENCE_OPERATOR_METHODS = %i[| ^ & + - * / % ** > >= < <= << >>].freeze

        # 'match' is a fairly generic name, so we don't flag it unless we see
        # a string or regexp literal on one side or the other
        def_node_matcher :match_call?, <<~PATTERN
          {(send {str regexp} :match _)
           (send !nil? :match {str regexp})}
        PATTERN

        def_node_matcher :only_truthiness_matters?, <<~PATTERN
          ^({if while until case while_post until_post} equal?(%0) ...)
        PATTERN

        def on_send(node)
          return unless match_call?(node) &&
                        (!node.value_used? || only_truthiness_matters?(node)) &&
                        !(node.parent && node.parent.block_type?)

          add_offense(node) do |corrector|
            autocorrect(corrector, node) if autocorrectable?(node)
          end
        end

        private

        def autocorrect(corrector, node)
          new_source = "#{node.receiver.source} =~ #{replacement(node)}"

          corrector.replace(node, new_source)
        end

        def autocorrectable?(node)
          # Regexp#match can take a second argument, but this cop doesn't
          # register an offense in that case
          node.receiver.regexp_type? || node.first_argument.regexp_type?
        end

        def replacement(node)
          arg = node.first_argument

          if requires_parentheses?(arg)
            "(#{arg.source})"
          else
            arg.source
          end
        end

        def requires_parentheses?(arg)
          return true if arg.if_type? && arg.ternary?
          return true if arg.operator_keyword? || arg.range_type?

          call_like?(arg) && requires_parentheses_for_call_like?(arg)
        end

        def requires_parentheses_for_call_like?(arg)
          return false if arg.parenthesized? || !arg.arguments?

          !HIGHER_PRECEDENCE_OPERATOR_METHODS.include?(arg.method_name)
        end

        def call_like?(arg)
          arg.type?(:call, :yield, :super)
        end
      end
    end
  end
end
