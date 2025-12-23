# frozen_string_literal: true

module Parser
  module Source

    ##
    # A processor which associates AST nodes with comments based on their
    # location in source code. It may be used, for example, to implement
    # rdoc-style processing.
    #
    # @example
    #   require 'parser/current'
    #
    #   ast, comments = Parser::CurrentRuby.parse_with_comments(<<-CODE)
    #   # Class stuff
    #   class Foo
    #     # Attr stuff
    #     # @see bar
    #     attr_accessor :foo
    #   end
    #   CODE
    #
    #   p Parser::Source::Comment.associate(ast, comments)
    #   # => {
    #   #   (class (const nil :Foo) ...) =>
    #   #     [#<Parser::Source::Comment (string):1:1 "# Class stuff">],
    #   #   (send nil :attr_accessor (sym :foo)) =>
    #   #     [#<Parser::Source::Comment (string):3:3 "# Attr stuff">,
    #   #      #<Parser::Source::Comment (string):4:3 "# @see bar">]
    #   # }
    #
    # @see {associate}
    #
    # @!attribute skip_directives
    #  Skip file processing directives disguised as comments.
    #  Namely:
    #
    #    * Shebang line,
    #    * Magic encoding comment.
    #
    #  @return [Boolean]
    #
    # @api public
    #
    class Comment::Associator
      attr_accessor :skip_directives

      ##
      # @param [Parser::AST::Node] ast
      # @param [Array<Parser::Source::Comment>] comments
      def initialize(ast, comments)
        @ast         = ast
        @comments    = comments

        @skip_directives = true
      end

      ##
      # Compute a mapping between AST nodes and comments.  Comment is
      # associated with the node, if it is one of the following types:
      #
      # - preceding comment, it ends before the node start
      # - sparse comment, it is located inside the node, after all child nodes
      # - decorating comment, it starts at the same line, where the node ends
      #
      # This rule is unambiguous and produces the result
      # one could reasonably expect; for example, this code
      #
      #     # foo
      #     hoge # bar
      #       + fuga
      #
      # will result in the following association:
      #
      #     {
      #       (send (lvar :hoge) :+ (lvar :fuga)) =>
      #         [#<Parser::Source::Comment (string):2:1 "# foo">],
      #       (lvar :fuga) =>
      #         [#<Parser::Source::Comment (string):3:8 "# bar">]
      #     }
      #
      # Note that comments after the end of the end of a passed tree range are
      # ignored (except root decorating comment).
      #
      # Note that {associate} produces unexpected result for nodes which are
      # equal but have distinct locations; comments for these nodes are merged.
      # You may prefer using {associate_by_identity} or {associate_locations}.
      #
      # @return [Hash<Parser::AST::Node, Array<Parser::Source::Comment>>]
      # @deprecated Use {associate_locations}.
      #
      def associate
        @map_using = :eql
        do_associate
      end

      ##
      # Same as {associate}, but uses `node.loc` instead of `node` as
      # the hash key, thus producing an unambiguous result even in presence
      # of equal nodes.
      #
      # @return [Hash<Parser::Source::Map, Array<Parser::Source::Comment>>]
      #
      def associate_locations
        @map_using = :location
        do_associate
      end

      ##
      # Same as {associate}, but compares by identity, thus producing an unambiguous
      # result even in presence of equal nodes.
      #
      # @return [Hash<Parser::Source::Node, Array<Parser::Source::Comment>>]
      #
      def associate_by_identity
        @map_using = :identity
        do_associate
      end

      private

      POSTFIX_TYPES = Set[:if, :while, :while_post, :until, :until_post, :masgn].freeze
      def children_in_source_order(node)
        if POSTFIX_TYPES.include?(node.type)
          # All these types have either nodes with expressions, or `nil`
          # so a compact will do, but they need to be sorted.
          node.children.compact.sort_by { |child| child.loc.expression.begin_pos }
        else
          node.children.select do |child|
            child.is_a?(AST::Node) && child.loc && child.loc.expression
          end
        end
      end

      def do_associate
        @mapping     = Hash.new { |h, k| h[k] = [] }
        @mapping.compare_by_identity if @map_using == :identity
        @comment_num = -1
        advance_comment

        advance_through_directives if @skip_directives

        visit(@ast) if @ast

        @mapping
      end

      def visit(node)
        process_leading_comments(node)

        return unless @current_comment

        # If the next comment is beyond the last line of this node, we don't
        # need to iterate over its subnodes
        # (Unless this node is a heredoc... there could be a comment in its body,
        # inside an interpolation)
        node_loc = node.location
        if @current_comment.location.line <= node_loc.last_line ||
           node_loc.is_a?(Map::Heredoc)
          children_in_source_order(node).each { |child| visit(child) }

          process_trailing_comments(node)
        end
      end

      def process_leading_comments(node)
        return if node.type == :begin
        while current_comment_before?(node) # preceding comment
          associate_and_advance_comment(node)
        end
      end

      def process_trailing_comments(node)
        while current_comment_before_end?(node)
          associate_and_advance_comment(node) # sparse comment
        end
        while current_comment_decorates?(node)
          associate_and_advance_comment(node) # decorating comment
        end
      end

      def advance_comment
        @comment_num += 1
        @current_comment = @comments[@comment_num]
      end

      def current_comment_before?(node)
        return false if !@current_comment
        comment_loc = @current_comment.location.expression
        node_loc = node.location.expression
        comment_loc.end_pos <= node_loc.begin_pos
      end

      def current_comment_before_end?(node)
        return false if !@current_comment
        comment_loc = @current_comment.location.expression
        node_loc = node.location.expression
        comment_loc.end_pos <= node_loc.end_pos
      end

      def current_comment_decorates?(node)
        return false if !@current_comment
        @current_comment.location.line == node.location.last_line
      end

      def associate_and_advance_comment(node)
        key = @map_using == :location ? node.location : node
        @mapping[key] << @current_comment
        advance_comment
      end

      MAGIC_COMMENT_RE = /^#\s*(-\*-|)\s*(frozen_string_literal|warn_indent|warn_past_scope):.*\1$/

      def advance_through_directives
        # Skip shebang.
        if @current_comment && @current_comment.text.start_with?('#!'.freeze)
          advance_comment
        end

        # Skip magic comments.
        if @current_comment && @current_comment.text =~ MAGIC_COMMENT_RE
          advance_comment
        end

        # Skip encoding line.
        if @current_comment && @current_comment.text =~ Buffer::ENCODING_RE
          advance_comment
        end
      end
    end

  end
end
