# frozen_string_literal: true

module Parser

  ##
  # {Parser::TreeRewriter} offers a basic API that makes it easy to rewrite
  # existing ASTs. It's built on top of {Parser::AST::Processor} and
  # {Parser::Source::TreeRewriter}
  #
  # For example, assume you want to remove `do` tokens from a while statement.
  # You can do this as following:
  #
  #     require 'parser/current'
  #
  #     class RemoveDo < Parser::TreeRewriter
  #       def on_while(node)
  #         # Check if the statement starts with "do"
  #         if node.location.begin.is?('do')
  #           remove(node.location.begin)
  #         end
  #       end
  #     end
  #
  #     code = <<-EOF
  #     while true do
  #       puts 'hello'
  #     end
  #     EOF
  #
  #     ast           = Parser::CurrentRuby.parse code
  #     buffer        = Parser::Source::Buffer.new('(example)', source: code)
  #     rewriter      = RemoveDo.new
  #
  #     # Rewrite the AST, returns a String with the new form.
  #     puts rewriter.rewrite(buffer, ast)
  #
  # This would result in the following Ruby code:
  #
  #     while true
  #       puts 'hello'
  #     end
  #
  # Keep in mind that {Parser::TreeRewriter} does not take care of indentation when
  # inserting/replacing code so you'll have to do this yourself.
  #
  # See also [a blog entry](http://whitequark.org/blog/2013/04/26/lets-play-with-ruby-code/)
  # describing rewriters in greater detail.
  #
  # @api public
  #
  class TreeRewriter < Parser::AST::Processor
    ##
    # Rewrites the AST/source buffer and returns a String containing the new
    # version.
    #
    # @param [Parser::Source::Buffer] source_buffer
    # @param [Parser::AST::Node] ast
    # @param [Symbol] crossing_deletions:, different_replacements:, swallowed_insertions:
    #                 policy arguments for TreeRewriter (optional)
    # @return [String]
    #
    def rewrite(source_buffer,
                ast,
                **policy)
      @source_rewriter = Parser::Source::TreeRewriter.new(source_buffer, **policy)

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
  end

end
