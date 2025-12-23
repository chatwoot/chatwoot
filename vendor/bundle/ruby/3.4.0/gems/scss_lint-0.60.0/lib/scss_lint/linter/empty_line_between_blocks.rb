# frozen_string_literal: true

module SCSSLint
  # Reports the lack of empty lines between block defintions.
  class Linter::EmptyLineBetweenBlocks < Linter
    include LinterRegistry

    def visit_atroot(node)
      check(node, '@at-root')
      yield
    end

    def visit_function(node)
      check(node, '@function')
      yield
    end

    def visit_media(node)
      check(node, '@media')
      yield
    end

    def visit_mixin(node)
      # Ignore @includes which don't have any block content
      check(node, '@include') if node.children
                                     .any? { |child| child.is_a?(Sass::Tree::Node) }
      yield
    end

    def visit_mixindef(node)
      check(node, '@mixin')
      yield
    end

    def visit_rule(node)
      check(node, 'Rule')
      yield
    end

  private

    MESSAGE_FORMAT = '%s declaration should be %s by an empty line'.freeze

    def check(node, type)
      return if config['ignore_single_line_blocks'] && node_on_single_line?(node)
      check_preceding_node(node, type)
      check_following_node(node, type)
    end

    def check_following_node(node, type)
      return unless (following_node = next_node(node)) &&
                    (next_start_line = following_node.line)

      # Special case: ignore comments immediately after a closing brace
      return if comment_after_closing_brace?(following_node, next_start_line)

      # Special case: ignore `@else` nodes which are children of the parent `@if`
      return if else_node?(following_node)

      # Otherwise check if line before the next node's starting line is blank
      return if next_line_blank?(next_start_line)

      add_lint(next_start_line - 1, MESSAGE_FORMAT % [type, 'followed'])
    end

    def comment_after_closing_brace?(node, next_start_line)
      line = engine.lines[next_start_line - 1].strip

      node.is_a?(Sass::Tree::CommentNode) &&
        line =~ %r{\s*\}?\s*/(/|\*)}
    end

    def next_line_blank?(next_start_line)
      engine.lines[next_start_line - 2].strip.empty?
    end

    # In cases where the previous node is not a block declaration, we won't
    # have run any checks against it, so we need to check here if the previous
    # line is an empty line
    def check_preceding_node(node, type)
      case prev_node(node)
      when
        nil,
        Sass::Tree::FunctionNode,
        Sass::Tree::MixinNode,
        Sass::Tree::MixinDefNode,
        Sass::Tree::RuleNode,
        Sass::Tree::CommentNode
        # Ignore
        nil
      else
        unless engine.lines[node.line - 2].strip.empty?
          add_lint(node.line, MESSAGE_FORMAT % [type, 'preceded'])
        end
      end
    end

    def next_node(node)
      return unless siblings = node_siblings(node)
      siblings[siblings.index(node) + 1] if siblings.count > 1
    end

    def prev_node(node)
      return unless siblings = node_siblings(node)
      index = siblings.index(node)
      siblings[index - 1] if index > 0 && siblings.count > 1
    end
  end
end
