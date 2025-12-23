# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `str`, `dstr`, and `xstr` nodes. This will be used
    # in place of a plain node when the builder constructs the AST, making
    # its methods available to all `str` nodes within RuboCop.
    class StrNode < Node
      include BasicLiteralNode

      PERCENT_LITERAL_TYPES = {
        :% => /\A%(?=[^a-zA-Z])/,
        :q => /\A%q/,
        :Q => /\A%Q/
      }.freeze
      private_constant :PERCENT_LITERAL_TYPES

      def single_quoted?
        loc_is?(:begin, "'")
      end

      def double_quoted?
        loc_is?(:begin, '"')
      end

      def character_literal?
        loc_is?(:begin, '?')
      end

      def heredoc?
        loc.is_a?(Parser::Source::Map::Heredoc)
      end

      # Checks whether the string literal is delimited by percent brackets.
      #
      # @overload percent_literal?
      #   Check for any string percent literal.
      #
      # @overload percent_literal?(type)
      #   Check for a string percent literal of type `type`.
      #
      # @param type [Symbol] an optional percent literal type
      #
      # @return [Boolean] whether the string is enclosed in percent brackets
      def percent_literal?(type = nil)
        return false unless loc?(:begin)

        if type
          loc.begin.source.match?(PERCENT_LITERAL_TYPES.fetch(type))
        else
          loc.begin.source.start_with?('%')
        end
      end
    end
  end
end
