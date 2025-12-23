# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for uses of double negation (`!!`) to convert something to a boolean value.
      #
      # When using `EnforcedStyle: allowed_in_returns`, allow double negation in contexts
      # that use boolean as a return value. When using `EnforcedStyle: forbidden`, double negation
      # should be forbidden always.
      #
      # NOTE: when `something` is a boolean value
      # `!!something` and `!something.nil?` are not the same thing.
      # As you're unlikely to write code that can accept values of any type
      # this is rarely a problem in practice.
      #
      # @safety
      #   Autocorrection is unsafe when the value is `false`, because the result
      #   of the expression will change.
      #
      #   [source,ruby]
      #   ----
      #   !!false     #=> false
      #   !false.nil? #=> true
      #   ----
      #
      # @example
      #   # bad
      #   !!something
      #
      #   # good
      #   !something.nil?
      #
      # @example EnforcedStyle: allowed_in_returns (default)
      #   # good
      #   def foo?
      #     !!return_value
      #   end
      #
      #   define_method :foo? do
      #     !!return_value
      #   end
      #
      #   define_singleton_method :foo? do
      #     !!return_value
      #   end
      #
      # @example EnforcedStyle: forbidden
      #   # bad
      #   def foo?
      #     !!return_value
      #   end
      #
      #   define_method :foo? do
      #     !!return_value
      #   end
      #
      #   define_singleton_method :foo? do
      #     !!return_value
      #   end
      class DoubleNegation < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        MSG = 'Avoid the use of double negation (`!!`).'
        RESTRICT_ON_SEND = %i[!].freeze

        # @!method double_negative?(node)
        def_node_matcher :double_negative?, '(send (send _ :!) :!)'

        def on_send(node)
          return unless double_negative?(node) && node.prefix_bang?
          return if style == :allowed_in_returns && allowed_in_returns?(node)

          location = node.loc.selector
          add_offense(location) do |corrector|
            corrector.remove(location)
            corrector.insert_after(node, '.nil?')
          end
        end

        private

        def allowed_in_returns?(node)
          node.parent&.return_type? || end_of_method_definition?(node)
        end

        def end_of_method_definition?(node)
          return false unless (def_node = find_def_node_from_ascendant(node))

          conditional_node = find_conditional_node_from_ascendant(node)
          last_child = find_last_child(def_node.send_type? ? def_node : def_node.body)

          if conditional_node
            double_negative_condition_return_value?(node, last_child, conditional_node)
          elsif last_child.type?(:pair, :hash) || last_child.parent.array_type?
            false
          else
            last_child.last_line <= node.last_line
          end
        end

        def find_def_node_from_ascendant(node)
          return unless (parent = node.parent)
          return parent if parent.any_def_type?
          return node.parent.child_nodes.first if define_method?(parent)

          find_def_node_from_ascendant(node.parent)
        end

        def define_method?(node)
          return false unless node.any_block_type?

          child = node.child_nodes.first
          return false unless child.send_type?

          child.method?(:define_method) || child.method?(:define_singleton_method)
        end

        def find_conditional_node_from_ascendant(node)
          return unless (parent = node.parent)
          return parent if parent.conditional?

          find_conditional_node_from_ascendant(parent)
        end

        def find_last_child(node)
          case node.type
          when :rescue
            find_last_child(node.body)
          when :ensure
            find_last_child(node.child_nodes.first)
          else
            node.child_nodes.last
          end
        end

        def double_negative_condition_return_value?(node, last_child, conditional_node)
          parent = find_parent_not_enumerable(node)
          if parent.begin_type?
            node.loc.line == parent.loc.last_line
          else
            last_child.last_line <= conditional_node.last_line
          end
        end

        def find_parent_not_enumerable(node)
          return unless (parent = node.parent)

          if parent.type?(:pair, :hash, :array)
            find_parent_not_enumerable(parent)
          else
            parent
          end
        end
      end
    end
  end
end
