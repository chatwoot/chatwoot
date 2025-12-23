# frozen_string_literal: true

module Faker
  class Books
    ##
    # A Faker module beyond your dreams, test data beyond your imagination.
    class Dune < Base
      class << self
        ##
        # Produces the name of a character from Dune
        #
        # @return [String]
        #
        # @example
        #   Faker::Books::Dune.character #=> "Leto Atreides"
        #
        # @faker.version 1.9.3
        def character
          fetch('dune.characters')
        end

        ##
        # @return [String]
        #
        # @example
        #   Faker::Books::Dune.title #=> "Duke"
        #
        # @faker.version 1.9.3
        def title
          fetch('dune.titles')
        end

        ##
        # Produces the name of a city from Dune
        #
        # @return [String]
        #
        # @example
        #   Faker::Books::Dune.city #=> "Arrakeen"
        #
        # @faker.version next
        def city
          fetch('dune.cities')
        end

        ##
        # Produces the name of a planet from Dune
        #
        # @return [String]
        #
        # @example
        #   Faker::Books::Dune.planet #=> "Caladan"
        #
        # @faker.version 1.9.3
        def planet
          fetch('dune.planets')
        end

        ##
        # Produces a quote from Dune
        #
        # @param character [String] The name of the character that the quote should be from
        #
        # @return [String]
        #
        # @example
        #   Faker::Books::Dune.quote
        #     #=> "A dead man, surely, no longer requires that water."
        # @example
        #   Faker::Books::Dune.quote(character: "baron_harkonnen")
        #     #=> "He who controls the spice, controls the universe!"
        #
        # @faker.version 1.9.3
        def quote(character: nil)
          quoted_characters = translate('faker.dune.quotes').keys

          if character.nil?
            character = sample(quoted_characters).to_s
          else
            character = character.to_s.downcase

            unless quoted_characters.include?(character.to_sym)
              raise ArgumentError,
                    "Characters quoted can be left blank or #{quoted_characters.join(', ')}"
            end
          end

          fetch("dune.quotes.#{character}")
        end

        ##
        # Produces a saying from Dune
        #
        # @param source [String]
        #
        # @return [String]
        #
        # @example
        #   Faker::Books::Dune.saying #=> "You do not beg the sun for mercy."
        # @example
        #   Faker::Books::Dune.saying(source: "fremen")
        #     #=> "May thy knife chip and shatter."
        #
        # @faker.version 1.9.3
        def saying(source: nil)
          sourced_sayings = translate('faker.dune.sayings').keys

          if source.nil?
            source = sample(sourced_sayings).to_s
          else
            source = source.to_s.downcase

            unless sourced_sayings.include?(source.to_sym)
              raise ArgumentError,
                    "Sources quoted in sayings can be left blank or #{sourced_sayings.join(', ')}"
            end
          end

          fetch("dune.sayings.#{source}")
        end
      end
    end
  end
end
