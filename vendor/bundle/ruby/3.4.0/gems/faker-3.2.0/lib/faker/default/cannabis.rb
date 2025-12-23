# frozen_string_literal: true

module Faker
  class Cannabis < Base
    ##
    # Produces a random strain.
    #
    # @return [String]
    #
    # @example
    #   Faker::Cannabis.strain #=> "Super Glue"
    #
    # @faker.version 1.9.1
    def self.strain
      fetch('cannabis.strains')
    end

    ##
    # Produces a random abbreviation.
    #
    # @return [String]
    #
    # @example
    #   Faker::Cannabis.cannabinoid_abbreviation #=> "CBGa"
    #
    # @faker.version 1.9.1
    def self.cannabinoid_abbreviation
      fetch('cannabis.cannabinoid_abbreviations')
    end

    ##
    # Produces a random cannabinoid type.
    #
    # @return [String]
    #
    # @example
    #   Faker::Cannabis.cannabinoid #=> "Cannabinolic Acid"
    #
    # @faker.version 1.9.1
    def self.cannabinoid
      fetch('cannabis.cannabinoids')
    end

    ##
    # Produces a random terpene type.
    #
    # @return [String]
    #
    # @example
    #   Faker::Cannabis.terpene #=> "Terpinene"
    #
    # @faker.version 1.9.1
    def self.terpene
      fetch('cannabis.terpenes')
    end

    ##
    # Produces a random kind of medical use.
    #
    # @return [String]
    #
    # @example
    #   Faker::Cannabis.medical_use #=> "anti-cancer"
    #
    # @faker.version 1.9.1
    def self.medical_use
      fetch('cannabis.medical_uses')
    end

    ##
    # Produces a random health benefit.
    #
    # @return [String]
    #
    # @example
    #   Faker::Cannabis.health_benefit #=> "prevents infection"
    #
    # @faker.version 1.9.1
    def self.health_benefit
      fetch('cannabis.health_benefits')
    end

    ##
    # Produces a random category.
    #
    # @return [String]
    #
    # @example
    #   Faker::Cannabis.category #=> "crystalline"
    #
    # @faker.version 1.9.1
    def self.category
      fetch('cannabis.categories')
    end

    ##
    # Produces a random type.
    #
    # @return [String]
    #
    # @example
    #   Faker::Cannabis.type #=> "indica"
    #
    # @faker.version 1.9.1
    def self.type
      fetch('cannabis.types')
    end

    ##
    # Produces a random buzzword.
    #
    # @return [String]
    #
    # @example
    #   Faker::Cannabis.buzzword #=> "high"
    #
    # @faker.version 1.9.1
    def self.buzzword
      fetch('cannabis.buzzwords')
    end

    ##
    # Produces a random brand.
    #
    # @return [String]
    #
    # @example
    #   Faker::Cannabis.brand #=> "Cannavore Confections"
    #
    # @faker.version 1.9.1
    def self.brand
      fetch('cannabis.brands')
    end
  end
end
