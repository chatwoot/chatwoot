# frozen_string_literal: true

require_relative 'parser.racc'

module RuboCop
  module AST
    class NodePattern
      # Parser for NodePattern
      # Note: class reopened in `parser.racc`
      #
      # Doc on how this fits in the compiling process:
      #   /docs/modules/ROOT/pages/node_pattern.adoc
      class Parser < Racc::Parser
        extend SimpleForwardable

        Builder = NodePattern::Builder
        Lexer = NodePattern::Lexer

        def initialize(builder = self.class::Builder.new)
          super()
          @builder = builder
        end

        ##
        # (Similar API to `parser` gem)
        # Parses a source and returns the AST.
        #
        # @param [Parser::Source::Buffer, String] source_buffer The source buffer to parse.
        # @return [NodePattern::Node]
        #
        def parse(source)
          @lexer = self.class::Lexer.new(source)
          do_parse
        rescue Lexer::Error => e
          raise NodePattern::Invalid, e.message
        ensure
          @lexer = nil # Don't keep references
        end

        def inspect
          "<##{self.class}>"
        end

        private

        def_delegators :@builder, :emit_list, :emit_unary_op, :emit_atom, :emit_capture,
                       :emit_call, :emit_union
        def_delegators :@lexer, :next_token

        def enforce_unary(node)
          return node if node.arity == 1

          detail = node.loc&.expression&.source || node.to_s
          raise NodePattern::Invalid, 'parse error, expected unary node pattern ' \
                                      "but got expression matching multiple elements: #{detail}"
        end

        # Overrides Racc::Parser's method:
        def on_error(token, val, _vstack)
          detail = token_to_str(token) || '?'
          raise NodePattern::Invalid, "parse error on value #{val.inspect} (#{detail})"
        end
      end
    end
  end
end
