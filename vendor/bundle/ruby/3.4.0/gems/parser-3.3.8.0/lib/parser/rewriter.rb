# frozen_string_literal: true

module Parser

  ##
  # {Parser::Rewriter} is deprecated. Use {Parser::TreeRewriter} instead.
  # It has a backwards compatible API and uses {Parser::Source::TreeRewriter}
  # instead of {Parser::Source::Rewriter}.
  # Please check the documentation for {Parser::Source::Rewriter} for details.
  #
  # @api public
  # @deprecated Use {Parser::TreeRewriter}
  #
  class Rewriter < Parser::AST::Processor
    ##
    # Rewrites the AST/source buffer and returns a String containing the new
    # version.
    #
    # @param [Parser::Source::Buffer] source_buffer
    # @param [Parser::AST::Node] ast
    # @return [String]
    #
    def rewrite(source_buffer, ast)
      @source_rewriter = Source::Rewriter.new(source_buffer)

      process(ast)

      @source_rewriter.process
    end

    ##
    # Returns `true` if the specified node is an assignment node, returns false
    # otherwise.
    #
    # @param [Parser::AST::Node] node
    # @return [Boolean]
    #
    def assignment?(node)
      [:lvasgn, :ivasgn, :gvasgn, :cvasgn, :casgn].include?(node.type)
    end

    ##
    # Removes the source range.
    #
    # @param [Parser::Source::Range] range
    #
    def remove(range)
      @source_rewriter.remove(range)
    end

    ##
    # Wraps the given source range with the given values.
    #
    # @param [Parser::Source::Range] range
    # @param [String] content
    #
    def wrap(range, before, after)
      @source_rewriter.wrap(range, before, after)
    end

    ##
    # Inserts new code before the given source range.
    #
    # @param [Parser::Source::Range] range
    # @param [String] content
    #
    def insert_before(range, content)
      @source_rewriter.insert_before(range, content)
    end

    ##
    # Inserts new code after the given source range.
    #
    # @param [Parser::Source::Range] range
    # @param [String] content
    #
    def insert_after(range, content)
      @source_rewriter.insert_after(range, content)
    end

    ##
    # Replaces the code of the source range `range` with `content`.
    #
    # @param [Parser::Source::Range] range
    # @param [String] content
    #
    def replace(range, content)
      @source_rewriter.replace(range, content)
    end

    DEPRECATION_WARNING = [
      'Parser::Rewriter is deprecated.',
      'Please update your code to use Parser::TreeRewriter instead'
    ].join("\n").freeze

    extend Deprecation

    def initialize(*)
      self.class.warn_of_deprecation
      Source::Rewriter.warned_of_deprecation = true
      super
    end
  end

end
