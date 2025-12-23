# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks that ActiveRecord aliases are not used. The direct method names
      # are more clear and easier to read.
      #
      # @safety
      #   This cop is unsafe because custom `update_attributes` method call was changed to
      #   `update` but the method name remained same in the method definition.
      #
      # @example
      #   # bad
      #   book.update_attributes!(author: 'Alice')
      #
      #   # good
      #   book.update!(author: 'Alice')
      class ActiveRecordAliases < Base
        extend AutoCorrector

        MSG = 'Use `%<prefer>s` instead of `%<current>s`.'

        ALIASES = { update_attributes: :update, update_attributes!: :update! }.freeze

        RESTRICT_ON_SEND = ALIASES.keys.freeze

        def on_send(node)
          return if node.arguments.empty?

          method_name = node.method_name
          alias_method = ALIASES[method_name]

          add_offense(
            node.loc.selector,
            message: format(MSG, prefer: alias_method, current: method_name),
            severity: :warning
          ) do |corrector|
            corrector.replace(node.loc.selector, alias_method)
          end
        end

        alias on_csend on_send
      end
    end
  end
end
