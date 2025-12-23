# frozen_string_literal: true

module Faker
  class Blockchain
    class Ethereum < Base
      class << self
        ##
        # Produces a random Ethereum wallet address
        #
        # @return [String]
        #
        # @example
        #   Faker::Blockchain::Ethereum.address
        #     #=> "0xd392b0c0500700d02d27ab30805ec80ddd3320ff"
        #
        # @faker.version 1.9.1
        def address
          hex_alphabet = '0123456789abcdef'
          var = +'0x'
          40.times { var << sample(shuffle(hex_alphabet.chars)) }
          var
        end
      end
    end
  end
end
