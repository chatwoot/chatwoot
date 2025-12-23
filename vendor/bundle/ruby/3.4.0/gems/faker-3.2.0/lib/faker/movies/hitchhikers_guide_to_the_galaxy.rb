# frozen_string_literal: true

module Faker
  class Movies
    class HitchhikersGuideToTheGalaxy < Base
      class << self
        ##
        # Produces a character from The Hitchhiker's Guide to the Galaxy.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::HitchhikersGuideToTheGalaxy.character #=> "Marvin"
        #
        # @faker.version 1.8.0
        def character
          fetch('hitchhikers_guide_to_the_galaxy.characters')
        end

        ##
        # Produces a location from The Hitchhiker's Guide to the Galaxy.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::HitchhikersGuideToTheGalaxy.location
        #     #=> "Arthur Dent's house"
        #
        # @faker.version 1.8.0
        def location
          fetch('hitchhikers_guide_to_the_galaxy.locations')
        end

        ##
        # Produces a Marvin quote from The Hitchhiker's Guide to the Galaxy.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::HitchhikersGuideToTheGalaxy.marvin_quote
        #     #=> "Life? Don't talk to me about life."
        #
        # @faker.version 1.8.0
        def marvin_quote
          fetch('hitchhikers_guide_to_the_galaxy.marvin_quote')
        end

        ##
        # Produces a planet from The Hitchhiker's Guide to the Galaxy.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::HitchhikersGuideToTheGalaxy.planet
        #     #=> "Magrathea"
        #
        # @faker.version 1.8.0
        def planet
          fetch('hitchhikers_guide_to_the_galaxy.planets')
        end

        ##
        # Produces a quote from The Hitchhiker's Guide to the Galaxy.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::HitchhikersGuideToTheGalaxy.quote
        #     #=> "In the beginning, the Universe was created. This has made a lot of people very angry and been widely regarded as a bad move."
        #
        # @faker.version 1.8.0
        def quote
          fetch('hitchhikers_guide_to_the_galaxy.quotes')
        end

        ##
        # Produces a species from The Hitchhiker's Guide to the Galaxy.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::HitchhikersGuideToTheGalaxy.specie
        #     #=> "Perfectly Normal Beast"
        #
        # @faker.version 1.8.0
        def specie
          fetch('hitchhikers_guide_to_the_galaxy.species')
        end

        ##
        # Produces a starship from The Hitchhiker's Guide to the Galaxy.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::HitchhikersGuideToTheGalaxy.starship
        #     #=> "Vogon Constructor Fleet"
        #
        # @faker.version 1.8.0
        def starship
          fetch('hitchhikers_guide_to_the_galaxy.starships')
        end
      end
    end
  end
end
