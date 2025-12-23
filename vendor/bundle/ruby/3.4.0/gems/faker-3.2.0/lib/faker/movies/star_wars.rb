# frozen_string_literal: true

module Faker
  class Movies
    class StarWars < Base
      class << self
        ##
        # Produces a call squadron from Star Wars.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::StarWars.call_squadron #=> "Green"
        #
        # @faker.version 1.6.2
        def call_squadron
          sample(call_squadrons)
        end

        ##
        # Produces a call sign from Star Wars.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::StarWars.call_sign #=> "Grey 5"
        #
        # @faker.version 1.6.2
        def call_sign
          numerify(parse('star_wars.call_sign'))
        end

        ##
        # Produces a call number from Star Wars.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::StarWars.call_number #=> "Leader"
        #
        # @faker.version 1.6.2
        def call_number
          sample(call_numbers)
        end

        ##
        # Produces a character from Star Wars.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::StarWars.character #=> "Anakin Skywalker"
        #
        # @faker.version 1.6.2
        def character
          sample(characters)
        end

        ##
        # Produces a droid from Star Wars.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::StarWars.droid #=> "C-3PO"
        #
        # @faker.version 1.6.2
        def droid
          sample(droids)
        end

        ##
        # Produces a planet from Star Wars.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::StarWars.planet #=> "Tatooine"
        #
        # @faker.version 1.6.2
        def planet
          sample(planets)
        end

        ##
        # Produces a species from Star Wars.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::StarWars.specie #=> "Gungan"
        #
        # @faker.version 1.6.2
        def specie
          sample(species)
        end

        ##
        # Produces a vehicle from Star Wars.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::StarWars.vehicle #=> "Sandcrawler"
        #
        # @faker.version 1.6.2
        def vehicle
          sample(vehicles)
        end

        # Produces a wookiee sentence from Star Wars.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::StarWars.wookiee_sentence #=> "Yrroonn ru ooma roo ahuma ur roooarrgh hnn-rowr."
        #
        # @faker.version 1.6.2
        def wookiee_sentence
          sentence = sample(wookiee_words).capitalize

          rand(0..10).times { sentence += " #{sample(wookiee_words)}" }

          sentence + sample(['.', '?', '!'])
        end

        ##
        # Produces a quote from Star Wars.
        #
        # @param character [String] The name of a character to derive a quote from.
        # @return [String]
        #
        # @example
        #   Faker::Movies::StarWars.quote #=> "Aren't you a little short for a Stormtrooper?"
        #
        # @example
        #   Faker::Movies::StarWars.quote(character: "leia_organa")
        #     #=> "Aren't you a little short for a Stormtrooper?"
        #
        # @faker.version 1.6.2
        def quote(character: nil)
          quoted_characters = translate('faker.star_wars.quotes')

          if character.nil?
            character = sample(quoted_characters.keys).to_s
          else
            character = character.to_s.downcase

            # check alternate spellings, nicknames, titles of characters
            translate('faker.star_wars.alternate_character_spellings').each do |k, v|
              character = k.to_s if v.include?(character)
            end

            raise ArgumentError, "Character for quotes can be left blank or #{quoted_characters.keys.join(', ')}" unless quoted_characters.key?(character.to_sym)
          end

          fetch("star_wars.quotes.#{character}")
        end

        ##
        # Generates numbers array
        #
        # @return [Array]
        #
        # @example
        #   Faker::Movies::StarWars.call_numbers  #=> ["Leader", "#"]
        #
        # @faker.version 1.6.2
        def call_numbers
          fetch_all('star_wars.call_numbers')
        end

        ##
        # Returns squadrons array
        #
        # @return [Array]
        #
        # @example
        #   Faker::Movies::StarWars.call_squadrons  #=> ["Rogue", "Red", "Gray", "Green", "Blue", "Gold", "Black", "Yellow", "Phoenix"]
        #
        # @faker.version 1.6.2
        def call_squadrons
          fetch_all('star_wars.call_squadrons')
        end

        ##
        # Returns all character names in movie
        #
        # @return [Array]
        #
        # @example
        #   Faker::Movies::StarWars.characters
        #
        # @faker.version 1.6.2
        def characters
          fetch_all('star_wars.characters')
        end

        ##
        # Returns droid list
        #
        # @return [Array]
        #
        # @example
        #   Faker::Movies::StarWars.droids
        #
        # @faker.versionn 1.6.2
        def droids
          fetch_all('star_wars.droids')
        end

        ##
        # Lists out all planet names
        #
        # @return [Array]
        #
        # @example
        #   Faker::Movies::StarWars.planets
        #
        # @faker.version 1.6.2
        def planets
          fetch_all('star_wars.planets')
        end

        ##
        # Returns name of all species
        #
        # @return [Array]
        #
        # @example
        #   Faker::Movies::StarWars.species
        #
        # @faker.version 1.6.2
        def species
          fetch_all('star_wars.species')
        end

        ##
        # Lists out all vehicles
        #
        # @return [Array]
        #
        # @example
        #   Faker::Movies::StarWars.vehicles
        #
        # @faker.version 1.6.2
        def vehicles
          fetch_all('star_wars.vehicles')
        end

        ##
        # All wookiee words
        #
        # @return [Array]
        #
        # @example
        #   Faker::Movies::StarWars.wookiee_words
        #
        # @faker.version 1.6.2
        def wookiee_words
          fetch_all('star_wars.wookiee_words')
        end

        alias wookie_sentence wookiee_sentence
        alias wookie_words wookiee_words
      end
    end
  end
end
