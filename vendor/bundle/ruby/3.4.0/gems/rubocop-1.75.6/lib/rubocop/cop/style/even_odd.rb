# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for places where `Integer#even?` or `Integer#odd?`
      # can be used.
      #
      # @example
      #
      #   # bad
      #   if x % 2 == 0
      #   end
      #
      #   # good
      #   if x.even?
      #   end
      class EvenOdd < Base
        extend AutoCorrector

        MSG = 'Replace with `Integer#%<method>s?`.'
        RESTRICT_ON_SEND = %i[== !=].freeze

        # @!method even_odd_candidate?(node)
        def_node_matcher :even_odd_candidate?, <<~PATTERN
          (send
            {(send $_ :% (int 2))
             (begin (send $_ :% (int 2)))}
            ${:== :!=}
            (int ${0 1}))
        PATTERN

        def on_send(node)
          even_odd_candidate?(node) do |base_number, method, arg|
            replacement_method = replacement_method(arg, method)
            add_offense(node, message: format(MSG, method: replacement_method)) do |corrector|
              correction = "#{base_number.source}.#{replacement_method}?"
              corrector.replace(node, correction)
            end
          end
        end

        private

        def replacement_method(arg, method)
          case arg
          when 0
            method == :== ? :even : :odd
          when 1
            method == :== ? :odd : :even
          end
        end
      end
    end
  end
end
