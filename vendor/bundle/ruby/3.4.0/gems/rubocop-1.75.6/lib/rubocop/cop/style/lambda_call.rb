# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for use of the lambda.(args) syntax.
      #
      # @example EnforcedStyle: call (default)
      #  # bad
      #  lambda.(x, y)
      #
      #  # good
      #  lambda.call(x, y)
      #
      # @example EnforcedStyle: braces
      #  # bad
      #  lambda.call(x, y)
      #
      #  # good
      #  lambda.(x, y)
      class LambdaCall < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        MSG = 'Prefer the use of `%<prefer>s` over `%<current>s`.'
        RESTRICT_ON_SEND = %i[call].freeze

        def on_send(node)
          return unless node.receiver

          if offense?(node)
            prefer = prefer(node)
            current = node.source

            add_offense(node, message: format(MSG, prefer: prefer, current: current)) do |corrector|
              next if part_of_ignored_node?(node)

              opposite_style_detected
              corrector.replace(node, prefer)

              ignore_node(node)
            end
          else
            correct_style_detected
          end
        end
        alias on_csend on_send

        private

        def offense?(node)
          (explicit_style? && node.implicit_call?) || (implicit_style? && !node.implicit_call?)
        end

        def prefer(node)
          receiver = node.receiver.source
          dot = node.loc.dot.source
          call_arguments = if node.arguments.empty?
                             ''
                           else
                             arguments = node.arguments.map(&:source).join(', ')
                             "(#{arguments})"
                           end
          method = explicit_style? ? "call#{call_arguments}" : "(#{arguments})"

          "#{receiver}#{dot}#{method}"
        end

        def implicit_style?
          style == :braces
        end

        def explicit_style?
          style == :call
        end
      end
    end
  end
end
