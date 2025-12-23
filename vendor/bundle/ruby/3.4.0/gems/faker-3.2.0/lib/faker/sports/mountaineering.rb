# frozen_string_literal: true

module Faker
  class Sports
    class Mountaineering < Base
      class << self
        ##
        # Produces the name of a Mountaineer.
        #
        # @return [String]
        #
        # @example
        #   Faker::Sports::Mountaineering.mountaineer #=> "Junko Tabei"
        #
        # @faker.version next
        def mountaineer
          fetch('mountaineering.mountaineer')
        end
      end
    end
  end
end
