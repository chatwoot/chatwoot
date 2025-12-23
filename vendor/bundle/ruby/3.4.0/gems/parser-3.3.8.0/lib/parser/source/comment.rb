# frozen_string_literal: true

module Parser
  module Source

    ##
    # A comment in the source code.
    #
    # @!attribute [r] text
    #  @return [String]
    #
    # @!attribute [r] location
    #  @return [Parser::Source::Range]
    #
    # @api public
    #
    class Comment
      attr_reader  :text

      attr_reader  :location
      alias_method :loc, :location

      ##
      # Associate `comments` with `ast` nodes by their corresponding node.
      #
      # @param [Parser::AST::Node] ast
      # @param [Array<Comment>]    comments
      # @return [Hash<Parser::AST::Node, Array<Comment>>]
      # @see Parser::Source::Comment::Associator#associate
      # @deprecated Use {associate_locations}.
      #
      def self.associate(ast, comments)
        associator = Associator.new(ast, comments)
        associator.associate
      end

      ##
      # Associate `comments` with `ast` nodes by their location in the
      # source.
      #
      # @param [Parser::AST::Node] ast
      # @param [Array<Comment>]    comments
      # @return [Hash<Parser::Source::Map, Array<Comment>>]
      # @see Parser::Source::Comment::Associator#associate_locations
      #
      def self.associate_locations(ast, comments)
        associator = Associator.new(ast, comments)
        associator.associate_locations
      end

      ##
      # Associate `comments` with `ast` nodes using identity.
      #
      # @param [Parser::AST::Node] ast
      # @param [Array<Comment>]    comments
      # @return [Hash<Parser::Source::Node, Array<Comment>>]
      # @see Parser::Source::Comment::Associator#associate_by_identity
      #
      def self.associate_by_identity(ast, comments)
        associator = Associator.new(ast, comments)
        associator.associate_by_identity
      end

      ##
      # @param [Parser::Source::Range] range
      #
      def initialize(range)
        @location = Parser::Source::Map.new(range)
        @text     = range.source.freeze

        freeze
      end

      ##
      # Type of this comment.
      #
      #   * Inline comments correspond to `:inline`:
      #
      #         # whatever
      #
      #   * Block comments correspond to `:document`:
      #
      #         =begin
      #         hi i am a document
      #         =end
      #
      # @return [Symbol]
      #
      def type
        if text.start_with?("#".freeze)
          :inline
        elsif text.start_with?("=begin".freeze)
          :document
        end
      end

      ##
      # @see #type
      # @return [Boolean] true if this is an inline comment.
      #
      def inline?
        type == :inline
      end

      ##
      # @see #type
      # @return [Boolean] true if this is a block comment.
      #
      def document?
        type == :document
      end

      ##
      # Compares comments. Two comments are equal if they
      # correspond to the same source range.
      #
      # @param [Object] other
      # @return [Boolean]
      #
      def ==(other)
        other.is_a?(Source::Comment) &&
          @location == other.location
      end

      ##
      # @return [String] a human-readable representation of this comment
      #
      def inspect
        "#<Parser::Source::Comment #{@location.expression.to_s} #{text.inspect}>"
      end
    end

  end
end
