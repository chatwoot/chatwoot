# frozen_string_literal: true

module Faker
  class TvShows
    class DrWho < Base
      flexible :dr_who

      class << self
        ##
        # Produces a character from Doctor Who.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::DrWho.character #=> "Captain Jack Harkness"
        #
        # @faker.version 1.8.0
        def character
          fetch('dr_who.character')
        end

        ##
        # Produces an iteration of The Doctor from Doctor Who.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::DrWho.the_doctor #=> "Ninth Doctor"
        #
        # @faker.version 1.8.0
        def the_doctor
          fetch('dr_who.the_doctors')
        end

        ##
        # Produces an actor from Doctor Who.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::DrWho.actor #=> "Matt Smith"
        #
        # @faker.version 1.9.0
        def actor
          fetch('dr_who.actors')
        end

        ##
        # Produces a catch phrase from Doctor Who.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::DrWho.catch_phrase #=> "Fantastic!"
        #
        # @faker.version 1.8.0
        def catch_phrase
          fetch('dr_who.catch_phrases')
        end

        ##
        # Produces a quote from Doctor Who.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::DrWho.quote #=> "Lots of planets have a north!"
        #
        # @faker.version 1.8.0
        def quote
          fetch('dr_who.quotes')
        end

        ##
        # Produces a villain from Doctor Who.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::DrWho.villain #=> "The Master"
        #
        # @faker.version 2.13.0
        def villain
          fetch('dr_who.villains')
        end

        ##
        # Produces a villain from Doctor Who.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::DrWho.villian #=> "The Master"
        #
        # @deprecated Use the correctly-spelled `villain` method instead.
        #
        # @faker.version 1.8.0
        alias villian villain

        ##
        # Produces a species from Doctor Who.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::DrWho.specie #=> "Dalek"
        #
        # @faker.version 1.8.0
        def specie
          fetch('dr_who.species')
        end
      end
    end
  end
end
