# frozen_string_literal: true

module Faker
  class JapaneseMedia
    class Naruto < Base
      class << self
        ##
        # Produces a character from Naruto.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::Naruto.character #=> "Naruto Uzumaki"
        #
        # @faker.version next
        def character
          fetch('naruto.characters')
        end

        ##
        # Produces a village from Naruto.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::Naruto.village #=> "Konohagakure (Leaf Village)"
        #
        # @faker.version next
        def village
          fetch('naruto.villages')
        end

        ##
        # Produces a eye from Naruto.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::Naruto.eye #=> "Konohagakure (Byakugan)"
        #
        # @faker.version next
        def eye
          fetch('naruto.eyes')
        end

        ##
        # Produces a demon from Naruto.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::Naruto.demon #=> "Nine-Tails (Kurama)"
        #
        # @faker.version next
        def demon
          fetch('naruto.demons')
        end
      end
    end
  end
end
