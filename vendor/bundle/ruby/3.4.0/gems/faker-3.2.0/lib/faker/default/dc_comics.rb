# frozen_string_literal: true

module Faker
  class DcComics < Base
    ##
    # Produces a hero name from DC Comics
    #
    # @return [String]
    #
    # @example
    #   Faker::DcComics.hero #=> "Batman"
    #
    # @faker.version 1.9.2
    def self.hero
      fetch('dc_comics.hero')
    end

    ##
    # Produces a heroine name from DC Comics
    #
    # @return [String]
    #
    # @example
    #   Faker::DcComics.heroine #=> "Supergirl"
    #
    # @faker.version 1.9.2
    def self.heroine
      fetch('dc_comics.heroine')
    end

    ##
    # Produces a villain name from DC Comics
    #
    # @return [String]
    #
    # @example
    #   Faker::DcComics.villain #=> "The Joker"
    #
    # @faker.version 1.9.2
    def self.villain
      fetch('dc_comics.villain')
    end

    ##
    # Produces a character name from DC Comics
    #
    # @return [String]
    #
    # @example
    #   Faker::DcComics.name #=> "Clark Kent"
    #
    # @faker.version 1.9.2
    def self.name
      fetch('dc_comics.name')
    end

    ##
    # Produces a comic book title from DC Comics
    #
    # @return [String]
    #
    # @example
    #   Faker::DcComics.title #=> "Batman: The Long Halloween"
    #
    # @faker.version 1.9.2
    def self.title
      fetch('dc_comics.title')
    end
  end
end
