# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for a specified error in checking raised errors.
      #
      # Enforces one of an Exception type, a string, or a regular
      # expression to match against the exception message as a parameter
      # to `raise_error`
      #
      # @example
      #   # bad
      #   expect {
      #     raise StandardError.new('error')
      #   }.to raise_error
      #
      #   # good
      #   expect {
      #     raise StandardError.new('error')
      #   }.to raise_error(StandardError)
      #
      #   expect {
      #     raise StandardError.new('error')
      #   }.to raise_error('error')
      #
      #   expect {
      #     raise StandardError.new('error')
      #   }.to raise_error(/err/)
      #
      #   expect { do_something }.not_to raise_error
      #
      class UnspecifiedException < Base
        MSG = 'Specify the exception being captured'

        RESTRICT_ON_SEND = %i[
          raise_exception
          raise_error
        ].freeze

        # @!method expect_to?(node)
        def_node_matcher :expect_to?, <<~PATTERN
          (send (block (send nil? :expect) ...) :to ...)
        PATTERN

        def on_send(node)
          return unless empty_exception_matcher?(node)

          add_offense(node)
        end

        private

        def empty_exception_matcher?(node)
          return false if node.arguments? || node.block_literal?

          expect_to = find_expect_to(node)
          return false unless expect_to
          return false if expect_to.block_node&.arguments?

          true
        end

        def find_expect_to(node)
          node.each_ancestor.find do |ancestor|
            break if ancestor.block_type?

            expect_to?(ancestor)
          end
        end
      end
    end
  end
end
