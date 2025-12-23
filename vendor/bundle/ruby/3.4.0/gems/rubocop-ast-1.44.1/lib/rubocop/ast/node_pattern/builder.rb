# frozen_string_literal: true

module RuboCop
  module AST
    class NodePattern
      # Responsible to build the AST nodes for `NodePattern`
      #
      # Doc on how this fits in the compiling process:
      #   /docs/modules/ROOT/pages/node_pattern.adoc
      class Builder
        def emit_capture(capture_token, node)
          return node if capture_token.nil?

          emit_unary_op(:capture, capture_token, node)
        end

        def emit_atom(type, value)
          n(type, [value])
        end

        def emit_unary_op(type, _operator = nil, *children)
          n(type, children)
        end

        def emit_list(type, _begin, children, _end)
          n(type, children)
        end

        def emit_call(type, selector, args = nil)
          _begin_t, arg_nodes, _end_t = args
          n(type, [selector, *arg_nodes])
        end

        def emit_union(begin_t, pattern_lists, end_t)
          children = union_children(pattern_lists)

          type = optimizable_as_set?(children) ? :set : :union
          emit_list(type, begin_t, children, end_t)
        end

        def emit_subsequence(node_list)
          return node_list.first if node_list.size == 1 # Don't put a single child in a subsequence

          emit_list(:subsequence, nil, node_list, nil)
        end

        private

        def optimizable_as_set?(children)
          children.all?(&:matches_within_set?)
        end

        def n(type, *args)
          Node::MAP[type].new(type, *args)
        end

        def union_children(pattern_lists)
          if pattern_lists.size == 1 # {a b c} => [[a, b, c]] => [a, b, c]
            children = pattern_lists.first
            raise NodePattern::Invalid, 'A union can not be empty' if children.empty?

            children
          else # { a b | c } => [[a, b], [c]] => [s(:subsequence, a, b), c]
            pattern_lists.map do |list|
              emit_subsequence(list)
            end
          end
        end
      end
    end
  end
end
