# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Ensures a consistent style is used when matching `nil`.
      #
      # You can either use the more specific `be_nil` matcher, or the more
      # generic `be` matcher with a `nil` argument.
      #
      # This cop can be configured using the `EnforcedStyle` option
      #
      # @example `EnforcedStyle: be_nil` (default)
      #   # bad
      #   expect(foo).to be(nil)
      #
      #   # good
      #   expect(foo).to be_nil
      #
      # @example `EnforcedStyle: be`
      #   # bad
      #   expect(foo).to be_nil
      #
      #   # good
      #   expect(foo).to be(nil)
      #
      class BeNil < Base
        extend AutoCorrector
        include ConfigurableEnforcedStyle

        BE_MSG = 'Prefer `be(nil)` over `be_nil`.'
        BE_NIL_MSG = 'Prefer `be_nil` over `be(nil)`.'
        RESTRICT_ON_SEND = %i[be be_nil].freeze

        # @!method be_nil_matcher?(node)
        def_node_matcher :be_nil_matcher?, <<~PATTERN
          (send nil? :be_nil)
        PATTERN

        # @!method nil_value_expectation?(node)
        def_node_matcher :nil_value_expectation?, <<~PATTERN
          (send nil? :be nil)
        PATTERN

        def on_send(node)
          case style
          when :be
            check_be_style(node)
          when :be_nil
            check_be_nil_style(node)
          else
            # :nocov:
            :noop
            # :nocov:
          end
        end

        private

        def check_be_style(node)
          return unless be_nil_matcher?(node)

          add_offense(node, message: BE_MSG) do |corrector|
            corrector.replace(node, 'be(nil)')
          end
        end

        def check_be_nil_style(node)
          return unless nil_value_expectation?(node)

          add_offense(node, message: BE_NIL_MSG) do |corrector|
            corrector.replace(node, 'be_nil')
          end
        end
      end
    end
  end
end
