# frozen_string_literal: true

require_relative 'music'

module Faker
  class Music
    class PearlJam < Base
      class << self
        ##
        # Produces the name of a member of Pearl Jam (current and former)
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::PearlJam.musician #=> "Eddie Vedder"
        #
        # @faker.version 2.13.0
        def musician
          fetch('pearl_jam.musicians')
        end

        ##
        # Produces the name of an album by Pearl Jam.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::PearlJam.album #=> "Ten"
        #
        # @faker.version 2.13.0
        def album
          fetch('pearl_jam.albums')
        end

        ##
        # Produces the name of a song by Pearl Jam.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::PearlJam.song #=> "Even Flow"
        #
        # @faker.version 2.13.0
        def song
          fetch('pearl_jam.songs')
        end
      end
    end
  end
end
