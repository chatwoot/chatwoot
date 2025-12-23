# frozen_string_literal: true

module Parser
  module Source

    ##
    # {Map} relates AST nodes to the source code they were parsed from.
    # More specifically, a {Map} or its subclass contains a set of ranges:
    #
    #  * `expression`: smallest range which includes all source corresponding
    #    to the node and all `expression` ranges of its children.
    #  * other ranges (`begin`, `end`, `operator`, ...): node-specific ranges
    #    pointing to various interesting tokens corresponding to the node.
    #
    # Note that the {Map::Heredoc} map is the only one whose `expression` does
    # not include other ranges. It only covers the heredoc marker (`<<HERE`),
    # not the here document itself.
    #
    # All ranges except `expression` are defined by {Map} subclasses.
    #
    # Ranges (except `expression`) can be `nil` if the corresponding token is
    # not present in source. For example, a hash may not have opening/closing
    # braces, and so would its source map.
    #
    #     p Parser::CurrentRuby.parse('[1 => 2]').children[0].loc
    #     # => <Parser::Source::Map::Collection:0x007f5492b547d8
    #     #  @end=nil, @begin=nil,
    #     #  @expression=#<Source::Range (string) 1...7>>
    #
    # The {file:doc/AST_FORMAT.md} document describes how ranges associated to source
    # code tokens. For example, the entry
    #
    #     (array (int 1) (int 2))
    #
    #     "[1, 2]"
    #      ^ begin
    #           ^ end
    #      ~~~~~~ expression
    #
    # means that if `node` is an {Parser::AST::Node} `(array (int 1) (int 2))`,
    # then `node.loc` responds to `begin`, `end` and `expression`, and
    # `node.loc.begin` returns a range pointing at the opening bracket, and so on.
    #
    # If you want to write code polymorphic by the source map (i.e. accepting
    # several subclasses of {Map}), use `respond_to?` instead of `is_a?` to
    # check whether the map features the range you need. Concrete {Map}
    # subclasses may not be preserved between versions, but their interfaces
    # will be kept compatible.
    #
    # You can visualize the source maps with `ruby-parse -E` command-line tool.
    #
    # @example
    #  require 'parser/current'
    #
    #  p Parser::CurrentRuby.parse('[1, 2]').loc
    #  # => #<Parser::Source::Map::Collection:0x007f14b80eccd8
    #  #  @end=#<Source::Range (string) 5...6>,
    #  #  @begin=#<Source::Range (string) 0...1>,
    #  #  @expression=#<Source::Range (string) 0...6>>
    #
    # @!attribute [r] node
    #  The node that is described by this map. Nodes and maps have 1:1 correspondence.
    #  @return [Parser::AST::Node]
    #
    # @!attribute [r] expression
    #  @return [Range]
    #
    # @api public
    #
    class Map
      attr_reader :node
      attr_reader :expression

      ##
      # @param [Range] expression
      def initialize(expression)
        @expression = expression
      end

      ##
      # @api private
      def initialize_copy(other)
        super
        @node = nil
      end

      ##
      # @api private
      def node=(node)
        @node = node
        freeze
        @node
      end

      ##
      # A shortcut for `self.expression.line`.
      # @return [Integer]
      #
      def line
        @expression.line
      end

      alias_method :first_line, :line

      ##
      # A shortcut for `self.expression.column`.
      # @return [Integer]
      #
      def column
        @expression.column
      end

      ##
      # A shortcut for `self.expression.last_line`.
      # @return [Integer]
      #
      def last_line
        @expression.last_line
      end

      ##
      # A shortcut for `self.expression.last_column`.
      # @return [Integer]
      #
      def last_column
        @expression.last_column
      end

      ##
      # @api private
      #
      def with_expression(expression_l)
        with { |map| map.update_expression(expression_l) }
      end

      ##
      # Compares source maps.
      # @return [Boolean]
      #
      def ==(other)
        other.class == self.class &&
          instance_variables.map do |ivar|
            instance_variable_get(ivar) ==
              other.send(:instance_variable_get, ivar)
          end.reduce(:&)
      end

      ##
      # Converts this source map to a hash with keys corresponding to
      # ranges. For example, if called on an instance of {Collection},
      # which adds the `begin` and `end` ranges, the resulting hash
      # will contain keys `:expression`, `:begin` and `:end`.
      #
      # @example
      #  require 'parser/current'
      #
      #  p Parser::CurrentRuby.parse('[1, 2]').loc.to_hash
      #  # => {
      #  #   :begin => #<Source::Range (string) 0...1>,
      #  #   :end => #<Source::Range (string) 5...6>,
      #  #   :expression => #<Source::Range (string) 0...6>
      #  # }
      #
      # @return [Hash<Symbol, Parser::Source::Range>]
      #
      def to_hash
        instance_variables.inject({}) do |hash, ivar|
          next hash if ivar.to_sym == :@node
          hash[ivar[1..-1].to_sym] = instance_variable_get(ivar)
          hash
        end
      end

      protected

      def with(&block)
        dup.tap(&block)
      end

      def update_expression(expression_l)
        @expression = expression_l
      end
    end

  end
end
