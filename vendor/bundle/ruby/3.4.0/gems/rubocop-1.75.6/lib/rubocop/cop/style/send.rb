# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for the use of the send method.
      #
      # @example
      #   # bad
      #   Foo.send(bar)
      #   quuz.send(fred)
      #
      #   # good
      #   Foo.__send__(bar)
      #   quuz.public_send(fred)
      class Send < Base
        MSG = 'Prefer `Object#__send__` or `Object#public_send` to `send`.'
        RESTRICT_ON_SEND = %i[send].freeze

        def on_send(node)
          return unless node.arguments?

          add_offense(node.loc.selector)
        end
        alias on_csend on_send
      end
    end
  end
end
