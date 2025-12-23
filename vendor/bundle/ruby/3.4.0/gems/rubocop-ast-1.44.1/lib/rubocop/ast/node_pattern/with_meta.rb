# frozen_string_literal: true

module RuboCop
  module AST
    class NodePattern
      class Parser
        # Overrides Parser to use `WithMeta` variants and provide additional methods
        class WithMeta < Parser
          # Overrides Lexer to token locations and comments
          class Lexer < NodePattern::Lexer
            attr_reader :source_buffer

            def initialize(str_or_buffer)
              @source_buffer = if str_or_buffer.respond_to?(:source)
                                 str_or_buffer
                               else
                                 ::Parser::Source::Buffer.new('(string)', source: str_or_buffer)
                               end
              @comments = []
              super(@source_buffer.source)
            end

            def token(type, value)
              super(type, [value, pos])
            end

            def emit_comment
              @comments << Comment.new(pos)
              super
            end

            # @return [::Parser::Source::Range] last match's position
            def pos
              ::Parser::Source::Range.new(source_buffer, ss.pos - ss.matched_size, ss.pos)
            end
          end

          # Overrides Builder to emit nodes with locations
          class Builder < NodePattern::Builder
            def emit_atom(type, token)
              value, loc = token
              begin_l = loc.resize(1)
              end_l = loc.end.adjust(begin_pos: -1)
              begin_l = nil if begin_l.source.match?(/\w/)
              end_l = nil if end_l.source.match?(/\w/)
              n(type, [value], source_map(token, begin_t: begin_l, end_t: end_l))
            end

            def emit_unary_op(type, operator_t = nil, *children)
              children[-1] = children[-1].first if children[-1].is_a?(Array) # token?
              map = source_map(children.first.source_range, operator_t: operator_t)
              n(type, children, map)
            end

            def emit_list(type, begin_t, children, end_t)
              expr = children.first.source_range.join(children.last.source_range)
              map = source_map(expr, begin_t: begin_t, end_t: end_t)
              n(type, children, map)
            end

            def emit_call(type, selector_t, args = nil)
              selector, = selector_t
              begin_t, arg_nodes, end_t = args

              map = source_map(selector_t, begin_t: begin_t, end_t: end_t, selector_t: selector_t)
              n(type, [selector, *arg_nodes], map)
            end

            private

            def n(type, children, source_map)
              super(type, children, { location: source_map })
            end

            def loc(token_or_range)
              return token_or_range[1] if token_or_range.is_a?(Array)

              token_or_range
            end

            def join_exprs(left_expr, right_expr)
              left_expr.source_range.join(right_expr.source_range)
            end

            def source_map(token_or_range, begin_t: nil, end_t: nil, operator_t: nil, selector_t: nil)
              expression_l = loc(token_or_range)
              expression_l = expression_l.expression if expression_l.respond_to?(:expression)
              locs = [begin_t, end_t, operator_t, selector_t].map { |token| loc(token) }
              begin_l, end_l, operator_l, selector_l = locs

              expression_l = locs.compact.inject(expression_l, :join)

              ::Parser::Source::Map::Send.new(_dot_l = nil, selector_l, begin_l, end_l, expression_l)
                                         .with_operator(operator_l)
            end
          end

          attr_reader :comments, :tokens

          def do_parse
            r = super
            @comments = @lexer.comments
            @tokens = @lexer.tokens
            r
          end
        end
      end
    end
  end
end
