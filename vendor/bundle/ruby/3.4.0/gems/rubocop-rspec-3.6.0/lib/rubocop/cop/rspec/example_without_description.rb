# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for examples without a description.
      #
      # RSpec allows for auto-generated example descriptions when there is no
      # description provided or the description is an empty one.
      # It is acceptable to use `specify` without a description
      #
      # This cop removes empty descriptions.
      # It also defines whether auto-generated description is allowed, based
      # on the configured style.
      #
      # This cop can be configured using the `EnforcedStyle` option
      #
      # @example
      #   # always good
      #   specify do
      #     result = service.call
      #     expect(result).to be(true)
      #   end
      #
      # @example `EnforcedStyle: always_allow` (default)
      #   # bad
      #   it('') { is_expected.to be_good }
      #   specify '' do
      #     result = service.call
      #     expect(result).to be(true)
      #   end
      #
      #   # good
      #   it { is_expected.to be_good }
      #   specify do
      #     result = service.call
      #     expect(result).to be(true)
      #   end
      #
      # @example `EnforcedStyle: single_line_only`
      #   # bad
      #   it('') { is_expected.to be_good }
      #   it do
      #     result = service.call
      #     expect(result).to be(true)
      #   end
      #
      #   # good
      #   it { is_expected.to be_good }
      #
      # @example `EnforcedStyle: disallow`
      #   # bad
      #   it { is_expected.to be_good }
      #   it do
      #     result = service.call
      #     expect(result).to be(true)
      #   end
      #
      class ExampleWithoutDescription < Base
        include ConfigurableEnforcedStyle

        MSG_DEFAULT_ARGUMENT = 'Omit the argument when you want to ' \
                               'have auto-generated description.'
        MSG_ADD_DESCRIPTION  = 'Add a description.'

        # @!method example_description(node)
        def_node_matcher :example_description, '(send nil? _ $(str $_))'

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless example?(node)

          check_example_without_description(node.send_node)

          example_description(node.send_node) do |message_node, message|
            return unless message.to_s.empty?

            add_offense(message_node, message: MSG_DEFAULT_ARGUMENT)
          end
        end

        private

        def check_example_without_description(node)
          return if node.arguments?
          return unless disallow_empty_description?(node)
          return if node.method?(:specify) && node.parent.multiline?

          add_offense(node, message: MSG_ADD_DESCRIPTION)
        end

        def disallow_empty_description?(node)
          style == :disallow ||
            (style == :single_line_only && node.parent.multiline?)
        end
      end
    end
  end
end
