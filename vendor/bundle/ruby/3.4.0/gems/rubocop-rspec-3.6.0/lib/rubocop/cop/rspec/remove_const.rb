# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks that `remove_const` is not used in specs.
      #
      # @example
      #   # bad
      #   it 'does something' do
      #     Object.send(:remove_const, :SomeConstant)
      #   end
      #
      #   before do
      #     SomeClass.send(:remove_const, :SomeConstant)
      #   end
      #
      class RemoveConst < Base
        include RuboCop::RSpec::Language

        MSG = 'Do not use remove_const in specs. ' \
              'Consider using e.g. `stub_const`.'
        RESTRICT_ON_SEND = %i[send __send__].freeze

        # @!method remove_const(node)
        def_node_matcher :remove_const, <<~PATTERN
          (send _ {:send | :__send__} (sym :remove_const) _)
        PATTERN

        # Check for offenses
        def on_send(node)
          remove_const(node) do
            add_offense(node)
          end
        end
      end
    end
  end
end
