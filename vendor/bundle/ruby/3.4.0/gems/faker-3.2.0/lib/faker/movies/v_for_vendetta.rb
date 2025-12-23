# frozen_string_literal: true

module Faker
  class Movies
    class VForVendetta < Base
      class << self
        ##
        # Produces a character from V For Vendetta.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::VForVendetta.character #=> "V"
        #
        # @faker.version 1.8.5
        def character
          fetch('v_for_vendetta.characters')
        end

        ##
        # Produces a speech from V For Vendetta.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::VForVendetta.speech
        #     #=> "Remember, remember, the Fifth of November, the Gunpowder Treason and Plot. I know of no reason why the Gunpowder Treason should ever be forgot..."
        #
        # @faker.version 1.8.5
        def speech
          fetch('v_for_vendetta.speeches')
        end

        ##
        # Produces a quote from V For Vendetta.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::VForVendetta.quote
        #     #=> "People should not be afraid of their governments. Governments should be afraid of their people."
        #
        # @faker.version 1.8.5
        def quote
          fetch('v_for_vendetta.quotes')
        end
      end
    end
  end
end
