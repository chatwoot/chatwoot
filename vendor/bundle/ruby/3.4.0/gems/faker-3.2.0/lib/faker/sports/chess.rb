# frozen_string_literal: true

module Faker
  class Sports
    class Chess < Base
      class << self
        ##
        # Produces the name of a chess player name.
        #
        # @return [String]
        #
        # @example
        #   Faker::Sports::Chess.player #=> "Golden State Warriors"
        #
        # @faker.version next
        def player
          fetch('chess.players')
        end

        ##
        # Produces a long (alpha-3) ISO 3166 country code.
        #
        # @return [String]
        #
        # @example
        #   Faker::Chess.federation #=> "COL"
        #
        # @faker.version next
        def federation
          Faker::Address.country_code_long
        end

        def tournament
          ##
          # Produces the name of a famous chess tournament name.
          #
          # @return [String]
          #
          # @example
          #   Faker::Chess.tournament #=> "Khanty-Mansisyk (Candidates Tournament)"
          #
          # @faker.version next
          fetch('chess.tournaments')
        end

        def rating(from: 2000, to: 2900)
          ##
          # Produces a rating between two provided values. Boundaries are inclusive.
          #
          # @param from [Numeric] The lowest number to include.
          # @param to [Numeric] The highest number to include.
          # @return [Numeric]
          #
          # @example
          #   Faker::Sports::Chess.rating #=> 2734
          #   Faker::Sports::Chess.rating(from: 2400, to: 2700) #=> 2580
          #
          # @faker.version next
          Faker::Base.rand_in_range(from, to)
        end

        ##
        # Produces the name of a chess opening.
        #
        # @return [String]
        #
        # @example
        #   Faker::Sports::Chess.opening #=> "Giuoco Piano"
        #
        # @faker.version next
        def opening
          fetch('chess.openings')
        end

        ##
        # Produces a chess title.
        #
        # @return [String]
        #
        # @example
        #   Faker::Sports::Chess.title #=> "GM"
        #
        # @faker.version next
        def title
          fetch('chess.titles')
        end
      end
    end
  end
end
