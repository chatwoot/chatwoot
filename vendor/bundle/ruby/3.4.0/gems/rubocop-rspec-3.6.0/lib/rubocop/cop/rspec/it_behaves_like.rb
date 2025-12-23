# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks that only one `it_behaves_like` style is used.
      #
      # @example `EnforcedStyle: it_behaves_like` (default)
      #   # bad
      #   it_should_behave_like 'a foo'
      #
      #   # good
      #   it_behaves_like 'a foo'
      #
      # @example `EnforcedStyle: it_should_behave_like`
      #   # bad
      #   it_behaves_like 'a foo'
      #
      #   # good
      #   it_should_behave_like 'a foo'
      #
      class ItBehavesLike < Base
        extend AutoCorrector
        include ConfigurableEnforcedStyle

        MSG = 'Prefer `%<replacement>s` over `%<original>s` when including ' \
              'examples in a nested context.'
        RESTRICT_ON_SEND = %i[it_behaves_like it_should_behave_like].freeze

        # @!method example_inclusion_offense(node)
        def_node_matcher :example_inclusion_offense, '(send _ % ...)'

        def on_send(node)
          example_inclusion_offense(node, alternative_style) do
            add_offense(node) do |corrector|
              corrector.replace(node.loc.selector, style.to_s)
            end
          end
        end

        private

        def message(_node)
          format(MSG, replacement: style, original: alternative_style)
        end
      end
    end
  end
end
