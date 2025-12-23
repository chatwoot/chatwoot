# frozen_string_literal: true

module RuboCop
  module Cop
    module FactoryBot
      # Check for excessive model creation in a list.
      #
      # @example MaxAmount: 10 (default)
      #   # We do not allow more than 10 items to be created
      #
      #   # bad
      #   create_list(:merge_request, 1000, state: :opened)
      #
      #   # good
      #   create_list(:merge_request, 10, state: :opened)
      #
      # @example MaxAmount: 20
      #   # We do not allow more than 20 items to be created
      #
      #   # bad
      #   create_list(:merge_request, 1000, state: :opened)
      #
      #   # good
      #   create_list(:merge_request, 15, state: :opened)
      #
      class ExcessiveCreateList < ::RuboCop::Cop::Base
        include ConfigurableExplicitOnly

        MESSAGE =
          'Avoid using `create_list` with more than %<max_amount>s items.'

        # @!method create_list?(node)
        def_node_matcher :create_list?, <<~PATTERN
          (send #factory_call? :create_list {sym str} $(int _) ...)
        PATTERN

        RESTRICT_ON_SEND = %i[create_list].freeze

        def on_send(node)
          number_node = create_list?(node)
          return unless number_node

          max_amount = cop_config['MaxAmount']
          return if number_node.value <= max_amount

          add_offense(number_node, message:
            format(MESSAGE, max_amount: max_amount))
        end
      end
    end
  end
end
