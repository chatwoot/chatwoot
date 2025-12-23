# frozen_string_literal: true

module SCSSLint
  # Checks the order of nested items within a rule set.
  class Linter::DeclarationOrder < Linter
    include LinterRegistry

    def check_order(node)
      check_node(node)
      yield # Continue linting children
    end

    alias visit_rule check_order
    alias visit_mixin check_order
    alias visit_media check_order

  private

    MESSAGE =
      'Rule sets should be ordered as follows: '\
      '`@extends`, `@includes` without `@content`, ' \
      'properties, `@includes` with `@content`, ' \
      'nested rule sets'.freeze

    MIXIN_WITH_CONTENT = 'mixin_with_content'.freeze

    DECLARATION_ORDER = [
      Sass::Tree::ExtendNode,
      Sass::Tree::MixinNode,
      Sass::Tree::PropNode,
      MIXIN_WITH_CONTENT,
      Sass::Tree::RuleNode,
    ].freeze

    def important_node?(node)
      DECLARATION_ORDER.include?(node.class)
    end

    def check_node(node)
      children = node.children.each_with_index
                     .select { |n, _| important_node?(n) }
                     .map { |n, i| [n, node_declaration_type(n), i] }

      sorted_children = children.sort do |(_, a_type, i), (_, b_type, j)|
        [DECLARATION_ORDER.index(a_type), i] <=> [DECLARATION_ORDER.index(b_type), j]
      end

      check_children_order(sorted_children, children)
    end

    # Find the child that is out of place
    def check_children_order(sorted_children, children)
      sorted_children.each_with_index do |sorted_item, index|
        next if sorted_item == children[index]

        add_lint(sorted_item.first.line,
                 "Expected item on line #{sorted_item.first.line} to appear " \
                 "before line #{children[index].first.line}. #{MESSAGE}")
        break
      end
    end

    def node_declaration_type(node)
      # If the node has no children, return the class.
      return node.class unless node.has_children

      # If the node is a mixin with children, indicate that;
      # otherwise, just return the class.
      return node.class unless node.is_a?(Sass::Tree::MixinNode)
      MIXIN_WITH_CONTENT
    end
  end
end
