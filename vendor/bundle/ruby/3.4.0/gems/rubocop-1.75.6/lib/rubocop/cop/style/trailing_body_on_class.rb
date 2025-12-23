# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for trailing code after the class definition.
      #
      # @example
      #   # bad
      #   class Foo; def foo; end
      #   end
      #
      #   # good
      #   class Foo
      #     def foo; end
      #   end
      #
      class TrailingBodyOnClass < Base
        include Alignment
        include TrailingBody
        extend AutoCorrector

        MSG = 'Place the first line of class body on its own line.'

        def on_class(node)
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
        alias on_sclass on_class
      end
    end
  end
end
