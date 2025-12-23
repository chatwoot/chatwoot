# frozen_string_literal: true

require 'openssl'
require 'securerandom'

module Faker
  class Blockchain
    class Bitcoin < Base
      class << self
        # @private
        PROTOCOL_VERSIONS = {
          main: 0,
          testnet: 111
        }.freeze

        ##
        # Produces a Bitcoin wallet address
        #
        # @return [String]
        #
        # @example
        #   Faker::Blockchain::Bitcoin.address
        #     #=> "147nDP22h3pHrLt2qykTH4txUwQh1ccaXp"
        #
        # @faker.version 1.9.2
        def address
          address_for(:main)
        end

        ##
        # Produces a Bitcoin testnet address
        #
        # @return [String]
        #
        # @example
        #   Faker::Blockchain::Bitcoin.testnet_address
        #     #=> "n4YjRyYD6V6zREpk6opqESDqD3KYnMdVEB"
        #
        # @faker.version 1.9.2
        def testnet_address
          address_for(:testnet)
        end

        protected

        ##
        # Generates a random Bitcoin address for the given network
        #
        # @param network [Symbol] The name of network protocol to generate an address for
        # @return [String] A Bitcoin address
        def address_for(network)
          version = PROTOCOL_VERSIONS.fetch(network)
          packed = version.chr + Faker::Config.random.bytes(20)
          checksum = OpenSSL::Digest::SHA256.digest(OpenSSL::Digest::SHA256.digest(packed))[0..3]
          Faker::Base58.encode(packed + checksum)
        end
      end
    end
  end
end
