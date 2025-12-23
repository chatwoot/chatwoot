# frozen_string_literal: true

require 'delegate'

module RuboCop
  module AST
    # This class performs a pattern-matching operation on an AST node.
    #
    # Detailed syntax: /docs/modules/ROOT/pages/node_pattern.adoc
    #
    # Initialize a new `NodePattern` with `NodePattern.new(pattern_string)`, then
    # pass an AST node to `NodePattern#match`. Alternatively, use one of the class
    # macros in `NodePattern::Macros` to define your own pattern-matching method.
    #
    # If the match fails, `nil` will be returned. If the match succeeds, the
    # return value depends on whether a block was provided to `#match`, and
    # whether the pattern contained any "captures" (values which are extracted
    # from a matching AST.)
    #
    # - With block: #match yields the captures (if any) and passes the return
    #               value of the block through.
    # - With no block, but one capture: the capture is returned.
    # - With no block, but multiple captures: captures are returned as an array.
    # - With no block and no captures: #match returns `true`.
    #
    class NodePattern
      # Helpers for defining methods based on a pattern string
      module Macros
        # Define a method which applies a pattern to an AST node
        #
        # The new method will return nil if the node does not match.
        # If the node matches, and a block is provided, the new method will
        # yield to the block (passing any captures as block arguments).
        # If the node matches, and no block is provided, the new method will
        # return the captures, or `true` if there were none.
        def def_node_matcher(method_name, pattern_str, **keyword_defaults)
          NodePattern.new(pattern_str).def_node_matcher(self, method_name, **keyword_defaults)
        end

        # Define a method which recurses over the descendants of an AST node,
        # checking whether any of them match the provided pattern
        #
        # If the method name ends with '?', the new method will return `true`
        # as soon as it finds a descendant which matches. Otherwise, it will
        # yield all descendants which match.
        def def_node_search(method_name, pattern_str, **keyword_defaults)
          NodePattern.new(pattern_str).def_node_search(self, method_name, **keyword_defaults)
        end
      end

      extend SimpleForwardable
      include MethodDefiner
      Invalid = Class.new(StandardError)

      VAR = 'node'

      # Yields its argument and any descendants, depth-first.
      #
      def self.descend(element, &block)
        return to_enum(__method__, element) unless block

        yield element

        if element.is_a?(::RuboCop::AST::Node)
          element.children.each do |child|
            descend(child, &block)
          end
        end

        nil
      end

      attr_reader :pattern, :ast, :match_code

      def_delegators :@compiler, :captures, :named_parameters, :positional_parameters

      def initialize(str, compiler: Compiler.new)
        @pattern = str
        @ast = compiler.parser.parse(str)
        @compiler = compiler
        @match_code = @compiler.compile_as_node_pattern(@ast, var: VAR)
        @cache = {}
      end

      def match(*args, **rest, &block)
        @cache[:lambda] ||= as_lambda
        @cache[:lambda].call(*args, block: block, **rest)
      end

      def ==(other)
        other.is_a?(NodePattern) && other.ast == ast
      end
      alias eql? ==

      def to_s
        "#<#{self.class} #{pattern}>"
      end

      def marshal_load(pattern) # :nodoc:
        initialize pattern
      end

      def marshal_dump # :nodoc:
        pattern
      end

      def as_json(_options = nil) # :nodoc:
        pattern
      end

      def encode_with(coder) # :nodoc:
        coder['pattern'] = pattern
      end

      def init_with(coder) # :nodoc:
        initialize(coder['pattern'])
      end

      def freeze
        @match_code.freeze
        @compiler.freeze
        super
      end
    end
  end
end
