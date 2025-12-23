# frozen_string_literal: true

require_relative 'music'

module Faker
  class Music
    class Rush < Base
      class << self
        ##
        # Produces the name of a member of Rush
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Rush.player #=> "Geddy Lee"
        #
        # @faker.version 2.13.0
        def player
          fetch('rush.players')
        end

        ##
        # Produces the name of an album by Rush
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::Rush.album #=> "Hold Your Fire"
        #
        # @faker.version 2.13.0
        def album
          fetch('rush.albums')
        end
      end
    end
  end
end
