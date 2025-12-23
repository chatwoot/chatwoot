# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Do not compute the size of statically sized objects.
      #
      # @example
      #   # String methods
      #   # bad
      #   'foo'.size
      #   %q[bar].count
      #   %(qux).length
      #
      #   # Symbol methods
      #   # bad
      #   :fred.size
      #   :'baz'.length
      #
      #   # Array methods
      #   # bad
      #   [1, 2, thud].count
      #   %W(1, 2, bar).size
      #
      #   # Hash methods
      #   # bad
      #   { a: corge, b: grault }.length
      #
      #   # good
      #   foo.size
      #   bar.count
      #   qux.length
      #
      #   # good
      #   :"#{fred}".size
      #   CONST = :baz.length
      #
      #   # good
      #   [1, 2, *thud].count
      #   garply = [1, 2, 3]
      #   garply.size
      #
      #   # good
      #   { a: corge, **grault }.length
      #   waldo = { a: corge, b: grault }
      #   waldo.size
      #
      class FixedSize < Base
        MSG = 'Do not compute the size of statically sized objects.'
        RESTRICT_ON_SEND = %i[count length size].freeze

        def_node_matcher :counter, <<~MATCHER
          (call ${array hash str sym} {:count :length :size} $...)
        MATCHER

        def on_send(node)
          return if node.ancestors.any? { |ancestor| allowed_parent?(ancestor) }

          counter(node) do |var, arg|
            return if allowed_variable?(var) || allowed_argument?(arg)

            add_offense(node)
          end
        end
        alias on_csend on_send

        private

        def allowed_variable?(var)
          contains_splat?(var) || contains_double_splat?(var)
        end

        def allowed_argument?(arg)
          arg && non_string_argument?(arg.first)
        end

        def allowed_parent?(node)
          node&.type?(:casgn, :any_block)
        end

        def contains_splat?(node)
          return false unless node.array_type?

          node.each_child_node(:splat).any?
        end

        def contains_double_splat?(node)
          return false unless node.hash_type?

          node.each_child_node(:kwsplat).any?
        end

        def non_string_argument?(node)
          node && !node.str_type?
        end
      end
    end
  end
end
