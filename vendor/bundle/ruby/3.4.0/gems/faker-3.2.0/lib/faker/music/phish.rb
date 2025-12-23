# frozen_string_literal: true

module Faker
  class Music
    class Phish < Base
      class << self
        ##
        # Produces the name of a album by Phish.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Phish.album #=> "Fuego"
        #
        # @faker.version 2.13.0
        def album
          fetch('phish.albums')
        end

        ##
        # Produces the name of a musician in Phish.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Phish.musician #=> "Trey Anastasio"
        #
        # @faker.version 2.13.0
        def musician
          fetch('phish.musicians')
        end

        ##
        # Produces the name of a song by Phish.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Phish.song #=> "Tweezer"
        #
        # @faker.version 1.9.2
        def song
          fetch('phish.songs')
        end
      end
    end
  end
end
