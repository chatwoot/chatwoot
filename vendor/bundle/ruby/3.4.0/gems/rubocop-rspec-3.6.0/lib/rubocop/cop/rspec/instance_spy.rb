# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for `instance_double` used with `have_received`.
      #
      # @example
      #   # bad
      #   it do
      #     foo = instance_double(Foo).as_null_object
      #     expect(foo).to have_received(:bar)
      #   end
      #
      #   # good
      #   it do
      #     foo = instance_spy(Foo)
      #     expect(foo).to have_received(:bar)
      #   end
      #
      class InstanceSpy < Base
        extend AutoCorrector

        MSG = 'Use `instance_spy` when you check your double ' \
              'with `have_received`.'

        # @!method null_double(node)
        def_node_search :null_double, <<~PATTERN
          (lvasgn $_
            (send
              $(send nil? :instance_double
                ...) :as_null_object))
        PATTERN

        # @!method have_received_usage(node)
        def_node_search :have_received_usage, <<~PATTERN
          (send
            (send nil? :expect
            (lvar $_)) :to
            (send nil? :have_received
            ...)
          ...)
        PATTERN

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless example?(node)

          null_double(node) do |var, receiver|
            have_received_usage(node) do |expected|
              next if expected != var

              add_offense(receiver) do |corrector|
                autocorrect(corrector, receiver)
              end
            end
          end
        end

        private

        def autocorrect(corrector, node)
          replacement = 'instance_spy'
          corrector.replace(node.loc.selector, replacement)

          double_source_map = node.parent.loc
          as_null_object_range = double_source_map
            .dot
            .join(double_source_map.selector)
          corrector.remove(as_null_object_range)
        end
      end
    end
  end
end
