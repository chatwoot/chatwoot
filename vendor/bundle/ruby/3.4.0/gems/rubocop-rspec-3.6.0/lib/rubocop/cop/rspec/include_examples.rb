# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for usage of `include_examples`.
      #
      # `include_examples`, unlike `it_behaves_like`, does not create its
      # own context. As such, using `subject`, `let`, `before`/`after`, etc.
      # within shared examples included with `include_examples` can have
      # unexpected behavior and side effects.
      #
      # Prefer using `it_behaves_like` instead.
      #
      # @example
      #   # bad
      #   include_examples 'examples'
      #
      #   # good
      #   it_behaves_like 'examples'
      #
      class IncludeExamples < Base
        extend AutoCorrector

        MSG = 'Prefer `it_behaves_like` over `include_examples`.'

        RESTRICT_ON_SEND = %i[include_examples].freeze

        def on_send(node)
          selector = node.loc.selector

          add_offense(selector) do |corrector|
            corrector.replace(selector, 'it_behaves_like')
          end
        end
      end
    end
  end
end
