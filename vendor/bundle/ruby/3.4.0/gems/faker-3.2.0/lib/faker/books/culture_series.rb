# frozen_string_literal: true

module Faker
  class Books
    class CultureSeries < Base
      flexible :culture_series

      class << self
        ##
        # @return [String]
        #
        # @example
        #   Faker::Books::CultureSeries.book
        #     #=> "The Player of Games"
        #
        # @faker.version 1.9.3
        def book
          fetch('culture_series.books')
        end

        ##
        # @return [String]
        #
        # @example
        #   Faker::Books::CultureSeries.culture_ship
        #     #=> "Fate Amenable To Change"
        #
        # @faker.version 1.9.3
        def culture_ship
          fetch('culture_series.culture_ships')
        end

        ##
        # @return [String]
        #
        # @example
        #   Faker::Books::CultureSeries.culture_ship_class
        #     #=> "General Systems Vehicle"
        #
        # @faker.version 1.9.3
        def culture_ship_class
          fetch('culture_series.culture_ship_classes')
        end

        ##
        # @return [String]
        #
        # @example
        #   Faker::Books::CultureSeries.culture_ship_class_abv
        #     #=> "The Odd Sister"
        #
        # @faker.version 1.9.3
        def culture_ship_class_abv
          fetch('culture_series.culture_ship_class_abvs')
        end

        ##
        # @return [String]
        #
        # @example
        #   Faker::Books::CultureSeries.civ
        #     #=> "Culture"
        #
        # @faker.version 1.9.3
        def civ
          fetch('culture_series.civs')
        end

        ##
        # @return [String]
        #
        # @example
        #   Faker::Books::CultureSeries.planet
        #     #=> "Xinth"
        #
        # @faker.version 1.9.3
        def planet
          fetch('culture_series.planets')
        end
      end
    end
  end
end
