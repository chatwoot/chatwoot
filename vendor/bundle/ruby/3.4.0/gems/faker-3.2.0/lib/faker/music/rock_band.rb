# frozen_string_literal: true

module Faker
  class Music
    class RockBand < Base
      class << self
        ##
        # Produces the name of a rock band.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::RockBand.name #=> "Led Zeppelin"
        #
        # @faker.version 1.7.0
        def name
          fetch('rock_band.name')
        end

        # Produces a rock song.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::RockBand.song #=> "Dani California"
        #
        # @faker.version next
        def song
          fetch('rock_band.song')
        end
      end
    end
  end
end
