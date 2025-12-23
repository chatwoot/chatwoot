# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Check that instances are not being stubbed globally.
      #
      # Prefer instance doubles over stubbing any instance of a class
      #
      # @example
      #   # bad
      #   describe MyClass do
      #     before { allow_any_instance_of(MyClass).to receive(:foo) }
      #   end
      #
      #   # good
      #   describe MyClass do
      #     let(:my_instance) { instance_double(MyClass) }
      #
      #     before do
      #       allow(MyClass).to receive(:new).and_return(my_instance)
      #       allow(my_instance).to receive(:foo)
      #     end
      #   end
      #
      class AnyInstance < Base
        MSG = 'Avoid stubbing using `%<method>s`.'
        RESTRICT_ON_SEND = %i[
          any_instance
          allow_any_instance_of
          expect_any_instance_of
        ].freeze

        def on_send(node)
          add_offense(node, message: format(MSG, method: node.method_name))
        end
      end
    end
  end
end
