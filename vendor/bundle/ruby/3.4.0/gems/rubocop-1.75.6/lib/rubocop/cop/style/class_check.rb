# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Enforces consistent use of `Object#is_a?` or `Object#kind_of?`.
      #
      # @example EnforcedStyle: is_a? (default)
      #   # bad
      #   var.kind_of?(Date)
      #   var.kind_of?(Integer)
      #
      #   # good
      #   var.is_a?(Date)
      #   var.is_a?(Integer)
      #
      # @example EnforcedStyle: kind_of?
      #   # bad
      #   var.is_a?(Time)
      #   var.is_a?(String)
      #
      #   # good
      #   var.kind_of?(Time)
      #   var.kind_of?(String)
      #
      class ClassCheck < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        MSG = 'Prefer `Object#%<prefer>s` over `Object#%<current>s`.'
        RESTRICT_ON_SEND = %i[is_a? kind_of?].freeze

        def on_send(node)
          return if style == node.method_name

          message = message(node)
          add_offense(node.loc.selector, message: message) do |corrector|
            replacement = node.method?(:is_a?) ? 'kind_of?' : 'is_a?'

            corrector.replace(node.loc.selector, replacement)
          end
        end
        alias on_csend on_send

        def message(node)
          if node.method?(:is_a?)
            format(MSG, prefer: 'kind_of?', current: 'is_a?')
          else
            format(MSG, prefer: 'is_a?', current: 'kind_of?')
          end
        end
      end
    end
  end
end
