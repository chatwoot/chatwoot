# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Prefer `select` or `reject` over `map { ... }.compact`.
      # This cop also handles `filter_map { ... }`, similar to `map { ... }.compact`.
      #
      # @example
      #
      #   # bad
      #   array.map { |e| some_condition? ? e : next }.compact
      #
      #   # bad
      #   array.filter_map { |e| some_condition? ? e : next }
      #
      #   # bad
      #   array.map do |e|
      #     if some_condition?
      #       e
      #     else
      #       next
      #     end
      #   end.compact
      #
      #   # bad
      #   array.map do |e|
      #     next if some_condition?
      #
      #     e
      #   end.compact
      #
      #   # bad
      #   array.map do |e|
      #     e if some_condition?
      #   end.compact
      #
      #   # good
      #   array.select { |e| some_condition? }
      #
      #   # good
      #   array.reject { |e| some_condition? }
      #
      class MapCompactWithConditionalBlock < Base
        extend AutoCorrector

        MSG = 'Replace `%<current>s` with `%<method>s`.'
        RESTRICT_ON_SEND = %i[compact filter_map].freeze

        # @!method conditional_block(node)
        def_node_matcher :conditional_block, <<~RUBY
          (block
            (call _ {:map :filter_map})
            (args
              $(arg _))
            {
              (if $_ $(lvar _) {next nil?})
              (if $_ {next nil?} $(lvar _))
              (if $_ (next $(lvar _)) {next nil nil?})
              (if $_ {next nil nil?} (next $(lvar _)))
              (begin
                {
                  (if $_ next nil?)
                  (if $_ nil? next)
                }
                $(lvar _))
              (begin
                {
                  (if $_ (next $(lvar _)) nil?)
                  (if $_ nil? (next $(lvar _)))
                }
                (nil))
            })
        RUBY

        def on_send(node)
          map_candidate = node.children.first
          if (block_argument, condition, return_value = conditional_block(map_candidate))
            return unless node.method?(:compact) && node.arguments.empty?

            range = map_with_compact_range(node)
          elsif (block_argument, condition, return_value = conditional_block(node.parent))
            return unless node.method?(:filter_map)

            range = filter_map_range(node)
          else
            return
          end

          inspect(node, block_argument, condition, return_value, range)
        end
        alias on_csend on_send

        private

        def inspect(node, block_argument_node, condition_node, return_value_node, range)
          return unless returns_block_argument?(block_argument_node, return_value_node)
          return if condition_node.parent.elsif?

          method = truthy_branch?(return_value_node) ? 'select' : 'reject'
          current = current(node)

          add_offense(range, message: format(MSG, current: current, method: method)) do |corrector|
            return if part_of_ignored_node?(node) || ignored_node?(node)

            corrector.replace(
              range, "#{method} { |#{block_argument_node.source}| #{condition_node.source} }"
            )

            ignore_node(node)
          end
        end

        def returns_block_argument?(block_argument_node, return_value_node)
          block_argument_node.name == return_value_node.children.first
        end

        def truthy_branch?(node)
          if node.parent.begin_type?
            truthy_branch_for_guard?(node)
          elsif node.parent.next_type?
            truthy_branch_for_if?(node.parent)
          else
            truthy_branch_for_if?(node)
          end
        end

        def truthy_branch_for_if?(node)
          if_node = node.parent

          if if_node.if? || if_node.ternary?
            if_node.if_branch == node
          elsif if_node.unless?
            if_node.else_branch == node
          end
        end

        def truthy_branch_for_guard?(node)
          if_node = node.left_sibling

          if if_node.if?
            if_node.if_branch.arguments.any?
          else
            if_node.if_branch.arguments.none?
          end
        end

        def current(node)
          if node.method?(:compact)
            map_or_filter_map_method = node.children.first

            "#{map_or_filter_map_method.method_name} { ... }.compact"
          else
            'filter_map { ... }'
          end
        end

        def map_with_compact_range(node)
          node.receiver.send_node.loc.selector.begin.join(node.source_range.end)
        end

        def filter_map_range(node)
          node.loc.selector.join(node.parent.source_range.end)
        end
      end
    end
  end
end
