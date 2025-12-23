# frozen_string_literal: true

module RuboCop
  module AST
    class NodePattern
      # A NodePattern comment, simplified version of ::Parser::Source::Comment
      class Comment
        attr_reader :location
        alias loc location

        ##
        # @param [Parser::Source::Range] range
        #
        def initialize(range)
          @location = ::Parser::Source::Map.new(range)
          freeze
        end

        # @return [String]
        def text
          loc.expression.source.freeze
        end

        ##
        # Compares comments. Two comments are equal if they
        # correspond to the same source range.
        #
        # @param [Object] other
        # @return [Boolean]
        #
        def ==(other)
          other.is_a?(Comment) &&
            @location == other.location
        end

        ##
        # @return [String] a human-readable representation of this comment
        #
        def inspect
          "#<NodePattern::Comment #{@location.expression} #{text.inspect}>"
        end
      end
    end
  end
end
