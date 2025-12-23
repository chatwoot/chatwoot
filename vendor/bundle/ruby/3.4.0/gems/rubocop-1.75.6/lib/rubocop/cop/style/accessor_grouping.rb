# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for grouping of accessors in `class` and `module` bodies.
      # By default it enforces accessors to be placed in grouped declarations,
      # but it can be configured to enforce separating them in multiple declarations.
      #
      # NOTE: If there is a method call before the accessor method it is always allowed
      # as it might be intended like Sorbet.
      #
      # NOTE: If there is a RBS::Inline annotation comment just after the accessor method
      # it is always allowed.
      #
      # @example EnforcedStyle: grouped (default)
      #   # bad
      #   class Foo
      #     attr_reader :bar
      #     attr_reader :bax
      #     attr_reader :baz
      #   end
      #
      #   # good
      #   class Foo
      #     attr_reader :bar, :bax, :baz
      #   end
      #
      #   # good
      #   class Foo
      #     # may be intended comment for bar.
      #     attr_reader :bar
      #
      #     sig { returns(String) }
      #     attr_reader :bax
      #
      #     may_be_intended_annotation :baz
      #     attr_reader :baz
      #   end
      #
      # @example EnforcedStyle: separated
      #   # bad
      #   class Foo
      #     attr_reader :bar, :baz
      #   end
      #
      #   # good
      #   class Foo
      #     attr_reader :bar
      #     attr_reader :baz
      #   end
      #
      class AccessorGrouping < Base
        include ConfigurableEnforcedStyle
        include RangeHelp
        include VisibilityHelp
        extend AutoCorrector

        GROUPED_MSG = 'Group together all `%<accessor>s` attributes.'
        SEPARATED_MSG = 'Use one attribute per `%<accessor>s`.'

        def on_class(node)
          class_send_elements(node).each do |macro|
            next unless macro.attribute_accessor?

            check(macro)
          end
        end
        alias on_sclass on_class
        alias on_module on_class

        private

        def check(send_node)
          return if previous_line_comment?(send_node) || !groupable_accessor?(send_node)
          return unless (grouped_style? && groupable_sibling_accessors(send_node).size > 1) ||
                        (separated_style? && send_node.arguments.size > 1)

          message = message(send_node)
          add_offense(send_node, message: message) do |corrector|
            autocorrect(corrector, send_node)
          end
        end

        def autocorrect(corrector, node)
          if (preferred_accessors = preferred_accessors(node))
            corrector.replace(node, preferred_accessors)
          else
            range = range_with_surrounding_space(node.source_range, side: :left)
            corrector.remove(range)
          end
        end

        def previous_line_comment?(node)
          comment_line?(processed_source[node.first_line - 2])
        end

        # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def groupable_accessor?(node)
          return true unless (previous_expression = node.left_siblings.last)

          # Accessors with Sorbet `sig { ... }` blocks shouldn't be groupable.
          if previous_expression.block_type?
            previous_expression.child_nodes.each do |child_node|
              break previous_expression = child_node if child_node.send_type?
            end
          end

          return true unless previous_expression.send_type?

          # Accessors with RBS::Inline annotations shouldn't be groupable.
          return false if processed_source.comments.any? do |c|
            same_line?(c, previous_expression) && c.text.start_with?('#:')
          end

          previous_expression.attribute_accessor? ||
            previous_expression.access_modifier? ||
            node.first_line - previous_expression.last_line > 1 # there is a space between nodes
        end
        # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

        def class_send_elements(class_node)
          class_def = class_node.body

          if !class_def || class_def.def_type?
            []
          elsif class_def.send_type?
            [class_def]
          else
            class_def.each_child_node(:send).to_a
          end
        end

        def grouped_style?
          style == :grouped
        end

        def separated_style?
          style == :separated
        end

        def groupable_sibling_accessor?(node, sibling)
          sibling.attribute_accessor? &&
            sibling.method?(node.method_name) &&
            node_visibility(sibling) == node_visibility(node) &&
            groupable_accessor?(sibling) && !previous_line_comment?(sibling)
        end

        def groupable_sibling_accessors(send_node)
          send_node.parent.each_child_node(:send).select do |sibling|
            groupable_sibling_accessor?(send_node, sibling)
          end
        end

        def message(send_node)
          msg = grouped_style? ? GROUPED_MSG : SEPARATED_MSG
          format(msg, accessor: send_node.method_name)
        end

        def preferred_accessors(node)
          if grouped_style?
            return if skip_for_grouping?(node)

            accessors = groupable_sibling_accessors(node)
            if node.loc == accessors.first.loc || skip_for_grouping?(accessors.first)
              group_accessors(node, accessors)
            end
          else
            separate_accessors(node)
          end
        end

        # Group after constants
        def skip_for_grouping?(node)
          node.right_siblings.any?(&:casgn_type?) &&
            node.right_siblings.any? { |n| n.send_type? && groupable_sibling_accessor?(node, n) }
        end

        def group_accessors(node, accessors)
          accessor_names = accessors.flat_map { |accessor| accessor.arguments.map(&:source) }.uniq

          "#{node.method_name} #{accessor_names.join(', ')}"
        end

        def separate_accessors(node)
          node.arguments.flat_map do |arg|
            lines = [
              *processed_source.ast_with_comments[arg].map(&:text),
              "#{node.method_name} #{arg.source}"
            ]
            if arg == node.first_argument
              lines
            else
              indent = ' ' * node.loc.column
              lines.map { |line| "#{indent}#{line}" }
            end
          end.join("\n")
        end
      end
    end
  end
end
