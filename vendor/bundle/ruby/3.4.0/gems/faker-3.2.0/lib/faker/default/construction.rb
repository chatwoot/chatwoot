# frozen_string_literal: true

module Faker
  class Construction < Base
    ##
    # Produces a random material.
    #
    # @return [String]
    #
    # @example
    #   Faker::Construction.material #=> "Wood"
    #
    # @faker.version 1.9.2
    def self.material
      fetch('construction.materials')
    end

    ##
    # Produces a random heavy equipment.
    #
    # @return [String]
    #
    # @example
    #   Faker::Construction.heavy_equipment #=> "Excavator"
    #
    # @faker.version 1.9.2
    def self.heavy_equipment
      fetch('construction.heavy_equipment')
    end

    ##
    # Produces a random trade.
    #
    # @return [String]
    #
    # @example
    #   Faker::Construction.trade #=> "Carpenter"
    #
    # @faker.version 1.9.2
    def self.trade
      fetch('construction.trades')
    end

    ##
    # Produces a random subcontract category.
    #
    # @return [String]
    #
    # @example
    #   Faker::Construction.subcontract_category #=> "Curb & Gutter"
    #
    # @faker.version 1.9.2
    def self.subcontract_category
      fetch('construction.subcontract_categories')
    end

    ##
    # Produces a random standard cost code.
    #
    # @return [String]
    #
    # @example
    #   Faker::Construction.standard_cost_code #=> "1-000 - Purpose"
    #
    # @faker.version 1.9.2
    def self.standard_cost_code
      fetch('construction.standard_cost_codes')
    end

    ##
    # Produces a random role.
    #
    # @return [String]
    #
    # @example
    #   Faker::Construction.role #=> "Engineer"
    #
    # @faker.version 1.9.2
    def self.role
      fetch('construction.roles')
    end
  end
end
