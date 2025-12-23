# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # When passing an existing hash as keyword arguments, provide additional arguments
      # directly rather than using `merge`.
      #
      # Providing arguments directly is more performant than using `merge`, and
      # also leads to shorter and simpler code.
      #
      # @example
      #   # bad
      #   some_method(**opts.merge(foo: true))
      #   some_method(**opts.merge(other_opts))
      #
      #   # good
      #   some_method(**opts, foo: true)
      #   some_method(**opts, **other_opts)
      #
      class KeywordArgumentsMerging < Base
        extend AutoCorrector

        MSG = 'Provide additional arguments directly rather than using `merge`.'

        # @!method merge_kwargs?(node)
        def_node_matcher :merge_kwargs?, <<~PATTERN
          (send _ _
            ...
            (hash
              (kwsplat
                $(send $_ :merge $...))
              ...))
        PATTERN

        def on_kwsplat(node)
          return unless (ancestor = node.parent&.parent)

          merge_kwargs?(ancestor) do |merge_node, hash_node, other_hash_node|
            add_offense(merge_node) do |corrector|
              autocorrect(corrector, node, hash_node, other_hash_node)
            end
          end
        end

        private

        def autocorrect(corrector, kwsplat_node, hash_node, other_hash_node)
          other_hash_node_replacement =
            other_hash_node.map do |node|
              if node.hash_type?
                if node.braces?
                  node.source[1...-1]
                else
                  node.source
                end
              else
                "**#{node.source}"
              end
            end.join(', ')

          corrector.replace(kwsplat_node, "**#{hash_node.source}, #{other_hash_node_replacement}")
        end
      end
    end
  end
end
