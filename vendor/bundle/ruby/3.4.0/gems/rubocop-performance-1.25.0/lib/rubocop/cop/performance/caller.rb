# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Identifies places where `caller[n]` can be replaced by `caller(n..n).first`.
      #
      # @example
      #   # bad
      #   caller[1]
      #   caller.first
      #   caller_locations[1]
      #   caller_locations.first
      #
      #   # good
      #   caller(2..2).first
      #   caller(1..1).first
      #   caller_locations(2..2).first
      #   caller_locations(1..1).first
      class Caller < Base
        extend AutoCorrector

        MSG = 'Use `%<preferred_method>s` instead of `%<current_method>s`.'
        RESTRICT_ON_SEND = %i[first []].freeze

        def_node_matcher :slow_caller?, <<~PATTERN
          {
            (send nil? {:caller :caller_locations})
            (send nil? {:caller :caller_locations} int)
          }
        PATTERN

        def_node_matcher :caller_with_scope_method?, <<~PATTERN
          {
            (send #slow_caller? :first)
            (send #slow_caller? :[] int)
          }
        PATTERN

        def on_send(node)
          return unless caller_with_scope_method?(node)

          method_name = node.receiver.method_name
          caller_arg = node.receiver.first_argument
          n = caller_arg ? int_value(caller_arg) : 1
          if node.method?(:[])
            m = int_value(node.first_argument)
            n += m
          end

          preferred_method = "#{method_name}(#{n}..#{n}).first"

          message = format(MSG, preferred_method: preferred_method, current_method: node.source)
          add_offense(node, message: message) do |corrector|
            corrector.replace(node, preferred_method)
          end
        end

        private

        def int_value(node)
          node.children[0]
        end
      end
    end
  end
end
