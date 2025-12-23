# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # The safe navigation operator returns nil if the receiver is
      # nil. If you chain an ordinary method call after a safe
      # navigation operator, it raises NoMethodError. We should use a
      # safe navigation operator after a safe navigation operator.
      # This cop checks for the problem outlined above.
      #
      # @example
      #
      #   # bad
      #   x&.foo.bar
      #   x&.foo + bar
      #   x&.foo[bar]
      #
      #   # good
      #   x&.foo&.bar
      #   x&.foo || bar
      class SafeNavigationChain < Base
        include NilMethods
        extend AutoCorrector
        extend TargetRubyVersion

        minimum_target_ruby_version 2.3

        MSG = 'Do not chain ordinary method call after safe navigation operator.'
        PLUS_MINUS_METHODS = %i[+@ -@].freeze

        # @!method bad_method?(node)
        def_node_matcher :bad_method?, <<~PATTERN
          {
            (send $(csend ...) $_ ...)
            (send $(any_block (csend ...) ...) $_ ...)
          }
        PATTERN

        def on_send(node)
          return unless require_safe_navigation?(node)

          bad_method?(node) do |safe_nav, method|
            return if nil_methods.include?(method) || PLUS_MINUS_METHODS.include?(node.method_name)

            begin_range = node.loc.dot || safe_nav.source_range.end
            location = begin_range.join(node.source_range.end)

            add_offense(location) do |corrector|
              autocorrect(corrector, offense_range: location, send_node: node)
            end
          end
        end

        private

        def require_safe_navigation?(node)
          parent = node.parent
          return true unless parent&.and_type?

          parent.rhs != node || parent.lhs.receiver != parent.rhs.receiver
        end

        # @param [Parser::Source::Range] offense_range
        # @param [RuboCop::AST::SendNode] send_node
        # @return [String]
        def add_safe_navigation_operator(offense_range:, send_node:)
          source =
            if brackets?(send_node)
              format(
                '%<method_name>s(%<arguments>s)%<method_chain>s',
                arguments: send_node.arguments.map(&:source).join(', '),
                method_name: send_node.method_name,
                method_chain: send_node.source_range.end.join(send_node.source_range.end).source
              )
            else
              offense_range.source
            end
          source.prepend('.') unless source.start_with?('.')
          source.prepend('&')
        end

        # @param [RuboCop::Cop::Corrector] corrector
        # @param [Parser::Source::Range] offense_range
        # @param [RuboCop::AST::SendNode] send_node
        def autocorrect(corrector, offense_range:, send_node:)
          corrector.replace(
            offense_range,
            add_safe_navigation_operator(offense_range: offense_range, send_node: send_node)
          )

          corrector.wrap(send_node, '(', ')') if require_parentheses?(send_node)
        end

        def brackets?(send_node)
          send_node.method?(:[]) || send_node.method?(:[]=)
        end

        def require_parentheses?(send_node)
          return true if operator_inside_hash?(send_node)
          return false unless send_node.comparison_method?
          return false unless (node = send_node.parent)

          (node.respond_to?(:logical_operator?) && node.logical_operator?) ||
            (node.respond_to?(:comparison_method?) && node.comparison_method?)
        end

        def operator_inside_hash?(send_node)
          # If an operator call (without a dot) is inside a hash, it needs
          # to be parenthesized when converted to safe navigation.
          send_node.parent&.pair_type? && !send_node.loc.dot
        end
      end
    end
  end
end
