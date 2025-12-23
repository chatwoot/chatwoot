# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Suggests `ENV.fetch` for the replacement of `ENV[]`.
      # `ENV[]` silently fails and returns `nil` when the environment variable is unset,
      # which may cause unexpected behaviors when the developer forgets to set it.
      # On the other hand, `ENV.fetch` raises `KeyError` or returns the explicitly
      # specified default value.
      #
      # @example
      #   # bad
      #   ENV['X']
      #   x = ENV['X']
      #
      #   # good
      #   ENV.fetch('X')
      #   x = ENV.fetch('X')
      #
      #   # also good
      #   !ENV['X']
      #   ENV['X'].some_method # (e.g. `.nil?`)
      #
      class FetchEnvVar < Base
        extend AutoCorrector

        MSG = 'Use `ENV.fetch(%<key>s)` or `ENV.fetch(%<key>s, nil)` instead of `ENV[%<key>s]`.'
        RESTRICT_ON_SEND = [:[]].freeze

        # @!method env_with_bracket?(node)
        def_node_matcher :env_with_bracket?, <<~PATTERN
          (send (const nil? :ENV) :[] $_)
        PATTERN

        def on_send(node)
          env_with_bracket?(node) do |name_node|
            break unless offensive?(node)

            message = format(MSG, key: name_node.source)
            add_offense(node, message: message) do |corrector|
              corrector.replace(node, new_code(name_node))
            end
          end
        end

        private

        def allowed_var?(node)
          env_key_node = node.children.last
          env_key_node.str_type? && cop_config['AllowedVars'].include?(env_key_node.value)
        end

        def used_as_flag?(node)
          return false if node.root?
          return true if used_if_condition_in_body(node)

          node.parent.send_type? && (node.parent.prefix_bang? || node.parent.comparison_method?)
        end

        def used_if_condition_in_body(node)
          if_node = node.ancestors.find(&:if_type?)

          return false unless (condition = if_node&.condition)
          return true if condition.send_type? && (condition.child_nodes == node.child_nodes)

          used_in_condition?(node, condition)
        end

        def used_in_condition?(node, condition)
          if condition.send_type?
            return true if condition.assignment_method? && partial_matched?(node, condition)
            return false if !condition.comparison_method? && !condition.predicate_method?
          end

          condition.child_nodes.any?(node)
        end

        # Avoid offending in the following cases:
        # `ENV['key'] if ENV['key'] = x`
        def partial_matched?(node, condition)
          node.child_nodes == node.child_nodes & condition.child_nodes
        end

        def offensive?(node)
          !(allowed_var?(node) || allowable_use?(node))
        end

        # Check if the node is a receiver and receives a message with dot syntax.
        def message_chained_with_dot?(node)
          return false if node.root?

          parent = node.parent
          return false if !parent.call_type? || parent.children.first != node

          parent.dot? || parent.safe_navigation?
        end

        # The following are allowed cases:
        #
        # - Used as a flag (e.g., `if ENV['X']` or `!ENV['X']`) because
        #   it simply checks whether the variable is set.
        # - Receiving a message with dot syntax, e.g. `ENV['X'].nil?`.
        # - `ENV['key']` assigned by logical AND/OR assignment.
        # - `ENV['key']` is the LHS of a `||`.
        def allowable_use?(node)
          used_as_flag?(node) || message_chained_with_dot?(node) || assigned?(node) || or_lhs?(node)
        end

        # The following are allowed cases:
        #
        # - `ENV['key']` is a receiver of `||=`, e.g. `ENV['X'] ||= y`.
        # - `ENV['key']` is a receiver of `&&=`, e.g. `ENV['X'] &&= y`.
        def assigned?(node)
          return false unless (parent = node.parent)&.assignment?

          lhs, _method, _rhs = *parent
          node == lhs
        end

        def or_lhs?(node)
          return false unless (parent = node.parent)&.or_type?

          parent.lhs == node || parent.parent&.or_type?
        end

        def new_code(name_node)
          "ENV.fetch(#{name_node.source}, nil)"
        end
      end
    end
  end
end
