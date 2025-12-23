# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Checks for redundant `:config` parameter in the `context` arguments.
      #
      # @example
      #
      #   # bad
      #   context 'foo', :config do
      #   end
      #
      #   # good
      #   context 'foo' do
      #   end
      #
      class RedundantContextConfigParameter < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Remove the redundant `:config` parameter.'
        RESTRICT_ON_SEND = %i[context].freeze

        def on_send(node)
          arguments = node.arguments
          config_node = arguments.detect { |argument| argument.source == ':config' }
          return unless config_node

          add_offense(config_node) do |corrector|
            dup_arguments = arguments.dup
            dup_arguments.delete(config_node)

            corrector.replace(offense_range(arguments), dup_arguments.map(&:source).join(', '))
          end
        end

        private

        def offense_range(arguments)
          range_between(arguments.first.source_range.begin_pos, arguments.last.source_range.end_pos)
        end
      end
    end
  end
end
