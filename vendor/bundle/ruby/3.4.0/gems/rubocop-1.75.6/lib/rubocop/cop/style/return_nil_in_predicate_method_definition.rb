# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for predicate method definitions that return `nil`.
      # A predicate method should only return a boolean value.
      #
      # @safety
      #   Autocorrection is marked as unsafe because the change of the return value
      #   from `nil` to `false` could potentially lead to incompatibility issues.
      #
      # @example
      #   # bad
      #   def foo?
      #     return if condition
      #
      #     do_something?
      #   end
      #
      #   # bad
      #   def foo?
      #     return nil if condition
      #
      #     do_something?
      #   end
      #
      #   # good
      #   def foo?
      #     return false if condition
      #
      #     do_something?
      #   end
      #
      #   # bad
      #   def foo?
      #     if condition
      #       nil
      #     else
      #       true
      #     end
      #   end
      #
      #   # good
      #   def foo?
      #     if condition
      #       false
      #     else
      #       true
      #     end
      #   end
      #
      # @example AllowedMethods: ['foo?']
      #   # good
      #   def foo?
      #     return if condition
      #
      #     do_something?
      #   end
      #
      # @example AllowedPatterns: [/foo/]
      #   # good
      #   def foo?
      #     return if condition
      #
      #     do_something?
      #   end
      #
      class ReturnNilInPredicateMethodDefinition < Base
        extend AutoCorrector
        include AllowedMethods
        include AllowedPattern

        MSG = 'Return `false` instead of `nil` in predicate methods.'

        # @!method return_nil?(node)
        def_node_matcher :return_nil?, <<~PATTERN
          {(return) (return (nil))}
        PATTERN

        def on_def(node)
          return unless node.predicate_method?
          return if allowed_method?(node.method_name) || matches_allowed_pattern?(node.method_name)
          return unless (body = node.body)

          body.each_descendant(:return) { |return_node| handle_return(return_node) }

          handle_implicit_return_values(body)
        end
        alias on_defs on_def

        private

        def last_node_of_type(node, type)
          return unless node
          return node if node_type?(node, type)
          return unless node.begin_type?
          return unless (last_child = node.children.last)

          last_child if last_child.is_a?(AST::Node) && node_type?(last_child, type)
        end

        def node_type?(node, type)
          node.type == type.to_sym
        end

        def register_offense(offense_node, replacement)
          add_offense(offense_node) do |corrector|
            corrector.replace(offense_node, replacement)
          end
        end

        def handle_implicit_return_values(node)
          handle_if(last_node_of_type(node, :if))
          handle_nil(last_node_of_type(node, :nil))
        end

        def handle_return(return_node)
          register_offense(return_node, 'return false') if return_nil?(return_node)
        end

        def handle_nil(nil_node)
          return unless nil_node

          register_offense(nil_node, 'false')
        end

        def handle_if(if_node)
          return unless if_node

          handle_implicit_return_values(if_node.if_branch)
          handle_implicit_return_values(if_node.else_branch)
        end
      end
    end
  end
end
