# frozen_string_literal: true

module Faker
  class Travel
    class Airport < Base
      class << self
        ##
        # Produces random Airport by name and takes arguments for size and region
        #
        # @param size [String] airport size, united_states has large, or medium, or small, european_union has large, or medium
        #
        # @param region [String] airport region, currently available -> united_states or european_union
        #
        # @retrun [String]
        #
        # @example
        # Faker::Travel::Airport.name(size: 'large', region: 'united_states') => "Los Angeles International Airport"
        #
        # @faker.version next
        def name(size:, region:)
          fetch("airport.#{region}.#{size}")
        end

        ##
        # Produces random Airport by IATA code and takes arguments for size and region
        #
        # @param size [String] airport size, united_states has large, or medium, or small, european_union has large, or medium
        #
        # @param region [String] airport region, currently available -> united_states or european_union
        #
        # @retrun [String]
        #
        # @example
        # Faker::Travel::Airport.iata(size: 'large', region: 'united_states') => "LAX"
        #
        # @faker.version next
        def iata(size:, region:)
          fetch("airport.#{region}.iata_code.#{size}")
        end
      end
    end
  end
end
