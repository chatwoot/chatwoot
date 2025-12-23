# frozen_string_literal: true

require_relative 'music'

module Faker
  class Music
    class GratefulDead < Base
      class << self
        ##
        # Produces the name of a member of The Grateful Dead.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::GratefulDead.player #=> "Jerry Garcia"
        #
        # @faker.version 1.9.2
        def player
          fetch('grateful_dead.players')
        end

        ##
        # Produces the name of a song by The Grateful Dead.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::GratefulDead.song #=> "Cassidy"
        #
        # @faker.version 1.9.2
        def song
          fetch('grateful_dead.songs')
        end
      end
    end
  end
end
