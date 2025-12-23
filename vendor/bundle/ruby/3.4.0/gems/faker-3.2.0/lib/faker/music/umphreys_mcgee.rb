# frozen_string_literal: true

module Faker
  class Music
    class UmphreysMcgee < Base
      class << self
        ##
        # Produces the name of a song by Umphrey's McGee.
        #
        # @return [String]
        #
        # @example
        #   Faker::Music::UmphreysMcgee.song #=> "Dump City"
        #
        # @faker.version 1.8.3
        def song
          fetch('umphreys_mcgee.song')
        end
      end
    end
  end
end
