# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Prefer bitwise predicate methods over direct comparison operations.
      #
      # @safety
      #   This cop is unsafe, as it can produce false positives if the receiver
      #   is not an `Integer` object.
      #
      # @example
      #
      #   # bad - checks any set bits
      #   (variable & flags).positive?
      #
      #   # good
      #   variable.anybits?(flags)
      #
      #   # bad - checks all set bits
      #   (variable & flags) == flags
      #
      #   # good
      #   variable.allbits?(flags)
      #
      #   # bad - checks no set bits
      #   (variable & flags).zero?
      #
      #   # good
      #   variable.nobits?(flags)
      #
      class BitwisePredicate < Base
        extend AutoCorrector
        extend TargetRubyVersion

        MSG = 'Replace with `%<preferred>s` for comparison with bit flags.'
        RESTRICT_ON_SEND = %i[!= == > >= positive? zero?].freeze

        minimum_target_ruby_version 2.5

        # @!method anybits?(node)
        def_node_matcher :anybits?, <<~PATTERN
          {
            (send #bit_operation? :positive?)
            (send #bit_operation? :> (int 0))
            (send #bit_operation? :>= (int 1))
            (send #bit_operation? :!= (int 0))
          }
        PATTERN

        # @!method allbits?(node)
        def_node_matcher :allbits?, <<~PATTERN
          {
            (send (begin (send _ :& _flags)) :== _flags)
            (send (begin (send _flags :& _)) :== _flags)
          }
        PATTERN

        # @!method nobits?(node)
        def_node_matcher :nobits?, <<~PATTERN
          {
            (send #bit_operation? :zero?)
            (send #bit_operation? :== (int 0))
          }
        PATTERN

        # @!method bit_operation?(node)
        def_node_matcher :bit_operation?, <<~PATTERN
          (begin
            (send _ :& _))
        PATTERN

        def on_send(node)
          return unless node.receiver&.begin_type?
          return unless (preferred_method = preferred_method(node))

          bit_operation = node.receiver.children.first
          lhs, _operator, rhs = *bit_operation
          preferred = "#{lhs.source}.#{preferred_method}(#{rhs.source})"

          add_offense(node, message: format(MSG, preferred: preferred)) do |corrector|
            corrector.replace(node, preferred)
          end
        end

        private

        def preferred_method(node)
          if anybits?(node)
            'anybits?'
          elsif allbits?(node)
            'allbits?'
          elsif nobits?(node)
            'nobits?'
          end
        end
      end
    end
  end
end
