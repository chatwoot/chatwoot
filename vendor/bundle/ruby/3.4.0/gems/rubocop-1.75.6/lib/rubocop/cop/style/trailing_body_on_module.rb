# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for trailing code after the module definition.
      #
      # @example
      #   # bad
      #   module Foo extend self
      #   end
      #
      #   # good
      #   module Foo
      #     extend self
      #   end
      #
      class TrailingBodyOnModule < Base
        include Alignment
        include TrailingBody
        extend AutoCorrector

        MSG = 'Place the first line of module body on its own line.'

        def on_module(node)
          return unless trailing_body?(node)

          add_offense(first_part_of(node.to_a.last)) do |corrector|
            LineBreakCorrector.correct_trailing_body(
              configured_width: configured_indentation_width,
              corrector: corrector,
              node: node,
              processed_source: processed_source
            )
          end
        end
      end
    end
  end
end
