# frozen_string_literal: true

module Faker
  class Movies
    class Tron < Base
      class << self
        ##
        # Produces a character from Tron.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Tron.character #=> "Bit"
        #
        # @faker.version next
        def character
          sample(characters)
        end

        ##
        # Produces a game from Tron.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Tron.game #=> "Space Paranoids"
        #
        # @faker.version next
        def game
          sample(games)
        end

        ##
        # Produces a location from Tron.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Tron.location #=> "Flynn's Arcade"
        #
        # @faker.version next
        def location
          sample(locations)
        end

        ##
        # Produces a program from Tron.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Tron.program #=> "Clu"
        #
        # @faker.version next
        def program
          sample(programs)
        end

        ##
        # Produces a quote from Tron.
        #
        # @param character [String] The name of a character to derive a quote from.
        # @return [String]
        #
        # @example
        #   Faker::Movies::Tron.quote #=> "Greetings, Programs!"
        #
        # @example
        #   Faker::Movies::Tron.quote(character: "mcp")
        #     #=> "End of Line."
        #
        # @faker.version next
        def quote(character: nil)
          quoted_characters = translate('faker.tron.quotes')

          if character.nil?
            character = sample(quoted_characters.keys).to_s
          else
            character = character.to_s.downcase

            # check alternate spellings, nicknames, titles of characters
            translate('faker.tron.alternate_character_spellings').each do |k, v|
              character = k.to_s if v.include?(character)
            end

            raise ArgumentError, "Character for quotes can be left blank or #{quoted_characters.keys.join(', ')}" unless quoted_characters.key?(character.to_sym)
          end

          fetch("tron.quotes.#{character}")
        end

        ##
        # Produces a tagline from Tron.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Tron.tagline #=> "The Electronic Gladiator"
        #
        # @faker.version next
        def tagline
          sample(taglines)
        end

        ##
        # Produces a user from Tron.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Tron.user #=> "Light Cycle"
        #
        # @faker.version next
        def user
          sample(users)
        end

        ##
        # Produces a vehicle from Tron.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Tron.vehicle #=> "Light Cycle"
        #
        # @faker.version next
        def vehicle
          sample(vehicles)
        end

        def characters
          translate('faker.tron.characters').values.flatten
        end

        def games
          fetch_all('tron.games')
        end

        def locations
          fetch_all('tron.locations')
        end

        def programs
          fetch_all('tron.characters.programs')
        end

        def taglines
          fetch_all('tron.taglines')
        end

        def users
          fetch_all('tron.characters.users')
        end

        def vehicles
          fetch_all('tron.vehicles')
        end
      end
    end
  end
end
