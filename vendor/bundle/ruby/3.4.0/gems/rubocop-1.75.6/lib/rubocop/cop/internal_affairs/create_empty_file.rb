# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Checks for uses of `create_file` with empty string second argument.
      #
      # @example
      #
      #   # bad
      #   create_file(path, '')
      #
      #   # good
      #   create_empty_file(path)
      #
      class CreateEmptyFile < Base
        extend AutoCorrector

        MSG = 'Use `%<replacement>s`.'
        RESTRICT_ON_SEND = %i[create_file].freeze

        def on_send(node)
          return if node.receiver
          return unless (argument = node.arguments[1])
          return unless argument.str_type? && argument.value.empty?

          replacement = "create_empty_file(#{node.first_argument.source})"
          message = format(MSG, replacement: replacement)

          add_offense(node, message: message) do |corrector|
            corrector.replace(node, replacement)
          end
        end
      end
    end
  end
end
