# frozen_string_literal: true

module Faker
  class JapaneseMedia
    class SwordArtOnline < Base
      class << self
        ##
        # Produces the real name of a character from Sword Art Online.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::SwordArtOnline.real_name #=> "Kirigaya Kazuto"
        #
        # @faker.version 1.9.0
        def real_name
          fetch('sword_art_online.real_name')
        end

        ##
        # Produces the in-game name of a character from Sword Art Online.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::SwordArtOnline.game_name #=> "Silica"
        #
        # @faker.version 1.9.0
        def game_name
          fetch('sword_art_online.game_name')
        end

        ##
        # Produces the name of a location from Sword Art Online.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::SwordArtOnline.location #=> "Ruby Palace"
        #
        # @faker.version 1.9.0
        def location
          fetch('sword_art_online.location')
        end

        ##
        # Produces the name of an item from Sword Art Online.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::SwordArtOnline.item #=> "Blackwyrm Coat"
        #
        # @faker.version 1.9.0
        def item
          fetch('sword_art_online.item')
        end
      end
    end
  end
end
