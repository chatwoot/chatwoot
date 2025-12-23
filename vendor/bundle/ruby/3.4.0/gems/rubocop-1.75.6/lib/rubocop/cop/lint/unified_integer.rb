# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for using Fixnum or Bignum constant.
      #
      # @example
      #
      #   # bad
      #   1.is_a?(Fixnum)
      #   1.is_a?(Bignum)
      #
      #   # good
      #   1.is_a?(Integer)
      class UnifiedInteger < Base
        extend AutoCorrector

        MSG = 'Use `Integer` instead of `%<klass>s`.'

        # @!method fixnum_or_bignum_const(node)
        def_node_matcher :fixnum_or_bignum_const, <<~PATTERN
          (:const {nil? (:cbase)} ${:Fixnum :Bignum})
        PATTERN

        def on_const(node)
          klass = fixnum_or_bignum_const(node)

          return unless klass

          add_offense(node, message: format(MSG, klass: klass)) do |corrector|
            next if target_ruby_version <= 2.3

            corrector.replace(node.loc.name, 'Integer')
          end
        end
      end
    end
  end
end
