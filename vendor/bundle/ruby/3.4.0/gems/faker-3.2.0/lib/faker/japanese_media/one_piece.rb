# frozen_string_literal: true

module Faker
  class JapaneseMedia
    class OnePiece < Base
      class << self
        ##
        # Produces a character from One Piece.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::OnePiece.character #=> "Monkey D. Luffy"
        #
        # @faker.version 1.8.5
        def character
          fetch('one_piece.characters')
        end

        ##
        # Produces a sea from One Piece.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::OnePiece.sea #=> "East Blue"
        #
        # @faker.version 1.8.5
        def sea
          fetch('one_piece.seas')
        end

        ##
        # Produces an island from One Piece.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::OnePiece.island #=> "Laftel"
        #
        # @faker.version 1.8.5
        def island
          fetch('one_piece.islands')
        end

        ##
        # Produces a location from One Piece.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::OnePiece.location #=> "Foosha Village"
        #
        # @faker.version 1.8.5
        def location
          fetch('one_piece.locations')
        end

        ##
        # Produces a quote from One Piece.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::OnePiece.quote #=> "ONE PIECE IS REAL!"
        #
        # @faker.version 1.8.5
        def quote
          fetch('one_piece.quotes')
        end

        ##
        # Produces an akuma no mi from One Piece.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::OnePiece.akuma_no_mi #=> "Gomu Gomu no Mi"
        #
        # @faker.version 1.8.5
        def akuma_no_mi
          fetch('one_piece.akuma_no_mi')
        end
      end
    end
  end
end
