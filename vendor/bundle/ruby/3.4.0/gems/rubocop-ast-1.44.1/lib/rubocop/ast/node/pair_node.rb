# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `pair` nodes. This will be used in place of a plain
    # node when the builder constructs the AST, making its methods available
    # to all `pair` nodes within RuboCop.
    class PairNode < Node
      include HashElementNode

      HASH_ROCKET = '=>'
      private_constant :HASH_ROCKET
      SPACED_HASH_ROCKET = ' => '
      private_constant :SPACED_HASH_ROCKET
      COLON = ':'
      private_constant :COLON
      SPACED_COLON = ': '
      private_constant :SPACED_COLON

      # Checks whether the `pair` uses a hash rocket delimiter.
      #
      # @return [Boolean] whether this `pair` uses a hash rocket delimiter
      def hash_rocket?
        loc.operator.is?(HASH_ROCKET)
      end

      # Checks whether the `pair` uses a colon delimiter.
      #
      # @return [Boolean] whether this `pair` uses a colon delimiter
      def colon?
        loc.operator.is?(COLON)
      end

      # Returns the delimiter of the `pair` as a string. Returns `=>` for a
      # colon delimited `pair` and `:` for a hash rocket delimited `pair`.
      #
      # @param [Boolean] with_spacing whether to include spacing
      # @return [String] the delimiter of the `pair`
      def delimiter(*deprecated, with_spacing: deprecated.first)
        if with_spacing
          hash_rocket? ? SPACED_HASH_ROCKET : SPACED_COLON
        else
          hash_rocket? ? HASH_ROCKET : COLON
        end
      end

      # Returns the inverse delimiter of the `pair` as a string.
      #
      # @param [Boolean] with_spacing whether to include spacing
      # @return [String] the inverse delimiter of the `pair`
      def inverse_delimiter(*deprecated, with_spacing: deprecated.first)
        if with_spacing
          hash_rocket? ? SPACED_COLON : SPACED_HASH_ROCKET
        else
          hash_rocket? ? COLON : HASH_ROCKET
        end
      end

      # Checks whether the value starts on its own line.
      #
      # @return [Boolean] whether the value in the `pair` starts its own line
      def value_on_new_line?
        key.loc.line != value.loc.line
      end

      # Checks whether the `pair` uses hash value omission.
      #
      # @return [Boolean] whether this `pair` uses hash value omission
      def value_omission?
        source.end_with?(':')
      end
    end
  end
end
