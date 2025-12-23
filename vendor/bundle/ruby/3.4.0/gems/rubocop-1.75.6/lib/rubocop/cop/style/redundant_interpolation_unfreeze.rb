# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Before Ruby 3.0, interpolated strings followed the frozen string literal
      # magic comment which sometimes made it necessary to explicitly unfreeze them.
      # Ruby 3.0 changed interpolated strings to always be unfrozen which makes
      # unfreezing them redundant.
      #
      # @example
      #   # bad
      #   +"#{foo} bar"
      #
      #   # bad
      #   "#{foo} bar".dup
      #
      #   # good
      #   "#{foo} bar"
      #
      class RedundantInterpolationUnfreeze < Base
        include FrozenStringLiteral
        extend AutoCorrector
        extend TargetRubyVersion

        MSG = "Don't unfreeze interpolated strings as they are already unfrozen."

        RESTRICT_ON_SEND = %i[+@ dup].freeze

        minimum_target_ruby_version 3.0

        def on_send(node)
          return if node.arguments?
          return unless (receiver = node.receiver)
          return unless receiver.dstr_type?
          return if uninterpolated_string?(receiver) || uninterpolated_heredoc?(receiver)

          add_offense(node.loc.selector) do |corrector|
            corrector.remove(node.loc.selector)
            corrector.remove(node.loc.dot) unless node.unary_operation?
          end
        end
      end
    end
  end
end
