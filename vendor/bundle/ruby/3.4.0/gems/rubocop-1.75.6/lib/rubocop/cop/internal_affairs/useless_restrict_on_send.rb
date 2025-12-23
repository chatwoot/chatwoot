# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Check for useless `RESTRICT_ON_SEND`.
      #
      # @example
      #   # bad
      #   class FooCop
      #     RESTRICT_ON_SEND = %i[bad_method].freeze
      #   end
      #
      #   # good
      #   class FooCop
      #     RESTRICT_ON_SEND = %i[bad_method].freeze
      #     def on_send(node)
      #       # ...
      #     end
      #   end
      #
      #   # good
      #   class FooCop
      #     RESTRICT_ON_SEND = %i[bad_method].freeze
      #     def after_send(node)
      #       # ...
      #     end
      #   end
      #
      class UselessRestrictOnSend < Base
        extend AutoCorrector

        MSG = 'Useless `RESTRICT_ON_SEND` is defined.'

        # @!method defined_send_callback?(node)
        def_node_search :defined_send_callback?, <<~PATTERN
          {
            (def {:on_send :after_send} ...)
            (alias (sym {:on_send :after_send}) _source ...)
            (send nil? :alias_method {(sym {:on_send :after_send}) (str {"on_send" "after_send"})} _source ...)
          }
        PATTERN

        def on_casgn(node)
          return if !restrict_on_send?(node) || defined_send_callback?(node.parent)

          add_offense(node) do |corrector|
            corrector.remove(node)
          end
        end

        private

        def restrict_on_send?(node)
          node.name == :RESTRICT_ON_SEND
        end
      end
    end
  end
end
