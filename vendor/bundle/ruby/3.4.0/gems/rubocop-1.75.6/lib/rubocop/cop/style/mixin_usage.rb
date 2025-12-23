# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks that `include`, `extend` and `prepend` statements appear
      # inside classes and modules, not at the top level, so as to not affect
      # the behavior of `Object`.
      #
      # @example
      #   # bad
      #   include M
      #
      #   class C
      #   end
      #
      #   # bad
      #   extend M
      #
      #   class C
      #   end
      #
      #   # bad
      #   prepend M
      #
      #   class C
      #   end
      #
      #   # good
      #   class C
      #     include M
      #   end
      #
      #   # good
      #   class C
      #     extend M
      #   end
      #
      #   # good
      #   class C
      #     prepend M
      #   end
      class MixinUsage < Base
        MSG = '`%<statement>s` is used at the top level. Use inside `class` or `module`.'
        RESTRICT_ON_SEND = %i[include extend prepend].freeze

        # @!method include_statement(node)
        def_node_matcher :include_statement, <<~PATTERN
          (send nil? ${:include :extend :prepend}
            const)
        PATTERN

        # @!method in_top_level_scope?(node)
        def_node_matcher :in_top_level_scope?, <<~PATTERN
          {
            root?                        # either at the top level
            ^[  {kwbegin begin if def}   # or wrapped within one of these
                #in_top_level_scope? ]   # that is in top level scope
          }
        PATTERN

        def on_send(node)
          include_statement(node) do |statement|
            return unless in_top_level_scope?(node)

            add_offense(node, message: format(MSG, statement: statement))
          end
        end
      end
    end
  end
end
