# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Looks for delegations that pass :allow_blank as an option
      # instead of :allow_nil. :allow_blank is not a valid option to pass
      # to ActiveSupport#delegate.
      #
      # @example
      #   # bad
      #   delegate :foo, to: :bar, allow_blank: true
      #
      #   # good
      #   delegate :foo, to: :bar, allow_nil: true
      class DelegateAllowBlank < Base
        extend AutoCorrector

        MSG = '`allow_blank` is not a valid option, use `allow_nil`.'
        RESTRICT_ON_SEND = %i[delegate].freeze

        def_node_matcher :allow_blank_option, <<~PATTERN
          (send nil? :delegate _ (hash <$(pair (sym :allow_blank) true) ...>))
        PATTERN

        def on_send(node)
          return unless (offending_node = allow_blank_option(node))

          add_offense(offending_node) do |corrector|
            corrector.replace(offending_node.key, 'allow_nil')
          end
        end
      end
    end
  end
end
