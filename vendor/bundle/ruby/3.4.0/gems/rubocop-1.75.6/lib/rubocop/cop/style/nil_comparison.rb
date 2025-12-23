# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for comparison of something with nil using `==` and
      # `nil?`.
      #
      # Supported styles are: predicate, comparison.
      #
      # @example EnforcedStyle: predicate (default)
      #
      #   # bad
      #   if x == nil
      #   end
      #
      #   # good
      #   if x.nil?
      #   end
      #
      # @example EnforcedStyle: comparison
      #
      #   # bad
      #   if x.nil?
      #   end
      #
      #   # good
      #   if x == nil
      #   end
      #
      class NilComparison < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        PREDICATE_MSG = 'Prefer the use of the `nil?` predicate.'
        EXPLICIT_MSG = 'Prefer the use of the `==` comparison.'

        RESTRICT_ON_SEND = %i[== === nil?].freeze

        # @!method nil_comparison?(node)
        def_node_matcher :nil_comparison?, '(send _ {:== :===} nil)'

        # @!method nil_check?(node)
        def_node_matcher :nil_check?, '(send _ :nil?)'

        def on_send(node)
          return unless node.receiver

          style_check?(node) do
            add_offense(node.loc.selector) do |corrector|
              new_code = if prefer_comparison?
                           node.source.sub('.nil?', ' == nil')
                         else
                           node.source.sub(/\s*={2,3}\s*nil/, '.nil?')
                         end

              corrector.replace(node, new_code)

              parent = node.parent
              corrector.wrap(node, '(', ')') if parent.respond_to?(:method?) && parent.method?(:!)
            end
          end
        end

        private

        def message(_node)
          prefer_comparison? ? EXPLICIT_MSG : PREDICATE_MSG
        end

        def style_check?(node, &block)
          if prefer_comparison?
            nil_check?(node, &block)
          else
            nil_comparison?(node, &block)
          end
        end

        def prefer_comparison?
          style == :comparison
        end
      end
    end
  end
end
