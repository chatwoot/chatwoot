# frozen_string_literal: true

module Faker
  class Music
    class Prince < Base
      class << self
        ##
        # Produces a random Prince song.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Prince.song #=> "Raspberry Beret"
        #   Faker::Music::Prince.song #=> "Starfish And Coffee"
        #
        # @faker.version 2.13.0
        def song
          fetch('prince.song')
        end

        ##
        # Produces a random Prince song lyric.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Prince.lyric #=> "Dearly beloved, we are gathered here today to get through this thing called life."
        #   Faker::Music::Prince.lyric #=> "You were so hard to find, the beautiful ones, they hurt you every time."
        #
        # @faker.version 2.13.0
        def lyric
          fetch('prince.lyric')
        end

        ##
        # Produces a random Prince album.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Prince.album #=> "The Gold Experience"
        #   Faker::Music::Prince.album #=> "Purple Rain"
        #
        # @faker.version 2.13.0
        def album
          fetch('prince.album')
        end

        ##
        # Produces a random Prince-associated band.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Prince.band #=> "The New Power Generation"
        #
        # @faker.version 2.13.0
        def band
          fetch('prince.band')
        end
      end
    end
  end
end
