# frozen_string_literal: true

module Faker
  class TvShows
    class SiliconValley < Base
      flexible :silicon_valley

      class << self
        ##
        # Produces a character from Silicon Valley.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::SiliconValley.character #=> "Jian Yang"
        #
        # @faker.version 1.8.5
        def character
          fetch('silicon_valley.characters')
        end

        ##
        # Produces a company from Silicon Valley.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::SiliconValley.company #=> "Bachmanity"
        #
        # @faker.version 1.8.5
        def company
          fetch('silicon_valley.companies')
        end

        ##
        # Produces a quote from Silicon Valley.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::SiliconValley.quote
        #     #=> "I don't want to live in a world where someone else is making the world a better place better than we are."
        #
        # @faker.version 1.8.5
        def quote
          fetch('silicon_valley.quotes')
        end

        ##
        # Produces an app from Silicon Valley.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::SiliconValley.app #=> "Nip Alert"
        #
        # @faker.version 1.8.5
        def app
          fetch('silicon_valley.apps')
        end

        ##
        # Produces an invention from Silicon Valley.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::SiliconValley.invention
        #     #=> "Tres Comas Tequila"
        #
        # @faker.version 1.8.5
        def invention
          fetch('silicon_valley.inventions')
        end

        ##
        # Produces a motto from Silicon Valley.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::SiliconValley.motto
        #     #=> "Our products are products, producing unrivaled results"
        #
        # @faker.version 1.8.5
        def motto
          fetch('silicon_valley.mottos')
        end

        ##
        # Produces a URL from Silicon Valley.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::SiliconValley.url #=> "http://www.piedpiper.com"
        #
        # @faker.version 1.8.5
        def url
          fetch('silicon_valley.urls')
        end

        ##
        # Produces an email address from Silicon Valley.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::SiliconValley.email #=> "richard@piedpiper.test"
        #
        # @faker.version 1.9.0
        def email
          fetch('silicon_valley.email')
        end
      end
    end
  end
end
