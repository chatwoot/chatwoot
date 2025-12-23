# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks void `expect()`.
      #
      # @example
      #   # bad
      #   expect(something)
      #
      #   # good
      #   expect(something).to be(1)
      #
      class VoidExpect < Base
        MSG = 'Do not use `expect()` without `.to` or `.not_to`. ' \
              'Chain the methods or remove it.'
        RESTRICT_ON_SEND = %i[expect].freeze

        # @!method expect?(node)
        def_node_matcher :expect?, <<~PATTERN
          (send nil? :expect ...)
        PATTERN

        # @!method expect_block?(node)
        def_node_matcher :expect_block?, <<~PATTERN
          (block #expect? (args) _body)
        PATTERN

        def on_send(node)
          return unless expect?(node)
          return unless inside_example?(node)

          check_expect(node)
        end

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless expect_block?(node)
          return unless inside_example?(node)

          check_expect(node)
        end

        private

        def check_expect(node)
          return unless void?(node)

          add_offense(node)
        end

        def void?(expect)
          parent = expect.parent
          return true if parent.begin_type?

          parent.block_type? && parent.body == expect
        end

        def inside_example?(node)
          node.each_ancestor(:block).any? { |ancestor| example?(ancestor) }
        end
      end
    end
  end
end
