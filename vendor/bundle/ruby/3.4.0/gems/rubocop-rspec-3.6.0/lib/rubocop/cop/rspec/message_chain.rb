# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Check that chains of messages are not being stubbed.
      #
      # @example
      #   # bad
      #   allow(foo).to receive_message_chain(:bar, :baz).and_return(42)
      #
      #   # good
      #   thing = Thing.new(baz: 42)
      #   allow(foo).to receive(:bar).and_return(thing)
      #
      class MessageChain < Base
        MSG = 'Avoid stubbing using `%<method>s`.'
        RESTRICT_ON_SEND = %i[receive_message_chain stub_chain].freeze

        def on_send(node)
          add_offense(
            node.loc.selector, message: format(MSG, method: node.method_name)
          )
        end
      end
    end
  end
end
