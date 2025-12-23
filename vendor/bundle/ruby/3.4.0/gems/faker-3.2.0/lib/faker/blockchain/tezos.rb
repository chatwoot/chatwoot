# frozen_string_literal: true

require 'openssl'
require 'securerandom'

module Faker
  class Blockchain
    class Tezos < Base
      class << self
        # @private
        PREFIXES = {
          tz1: [6, 161, 159],
          KT1: [2, 90, 121],
          edpk: [13, 15, 37, 217],
          edsk: [13, 15, 58, 7],
          edsig: [9, 245, 205, 134, 18],
          B: [1, 52],
          o: [5, 116]
        }.freeze

        ##
        # Produces a random Tezos account address
        #
        # @return [String]
        #
        # @example
        #   Faker::Blockchain::Tezos.account
        #     #=> "tz1eUsgK6aj752Fbxwk5sAoEFvSDnPjZ4qvk"
        #
        # @faker.version 1.9.2
        def account
          encode_tz(:tz1, 20)
        end

        ##
        # Produces a random Tezos contract
        #
        # @return [String]
        #
        # @example
        #   Faker::Blockchain::Tezos.contract
        #     #=> "KT1MroqeP15nnitB4CnNfkqHYa2NErhPPLWF"
        #
        # @faker.version 1.9.2
        def contract
          encode_tz(:KT1, 20)
        end

        ##
        # Produces a random Tezos operation
        #
        # @return [String]
        #
        # @example
        #   Faker::Blockchain::Tezos.operation
        #     #=> "onygWYXJX3xNstFLv9PcCrhQdCkENC795xwSinmTEc1jsDN4VDa"
        #
        # @faker.version 1.9.2
        def operation
          encode_tz(:o, 32)
        end

        ##
        # Produces a random Tezos block
        #
        # @return [String]
        #
        # @example
        #   Faker::Blockchain::Tezos.block
        #     #=> "BMbhs2rkY1dvAkAyRytvPsjFQ2RiPrBhYkxvWpY65dzkdSuw58a"
        #
        # @faker.version 1.9.4
        def block
          encode_tz(:B, 32)
        end

        ##
        # Produces a random Tezos signature
        #
        # @return [String]
        #
        # @example
        #   Faker::Blockchain::Tezos.signature
        #     #=> "edsigu165B7VFf3Dpw2QABVzEtCxJY2gsNBNcE3Ti7rRxtDUjqTFRpg67EdAQmY6YWPE5tKJDMnSTJDFu65gic8uLjbW2YwGvAZ"
        #
        # @faker.version 1.9.2
        def signature
          encode_tz(:edsig, 64)
        end

        ##
        # Produces a random Tezos public key
        #
        # @return [String]
        #
        # @example
        #   Faker::Blockchain::Tezos.public_key
        #     #=> "edpkuib9x8QXRc5nWwHUg7U1dXsVmaUrUNU5sX9pVEEvwbMVdfMCeq"
        #
        # @faker.version 2.15.2
        def public_key
          encode_tz(:edpk, 32)
        end

        ##
        # Produces a random Tezos public key
        #
        # @return [String]
        #
        # @example
        #   Faker::Blockchain::Tezos.secret_key
        #     #=> "edsk3HZCAGEGpzQPnQUwQeFY4ESanFhQCgLpKriQw8GHyhKCrjHawv"
        #
        # @faker.version 2.15.2
        def secret_key
          encode_tz(:edsk, 32)
        end

        protected

        ##
        # @param prefix [Symbol]
        # @param payload_size [Integer] The size of the payload
        #
        # @return [String]
        def encode_tz(prefix, payload_size)
          prefix = PREFIXES.fetch(prefix)
          packed = prefix.map(&:chr).join + Faker::Config.random.bytes(payload_size)
          checksum = OpenSSL::Digest::SHA256.digest(OpenSSL::Digest::SHA256.digest(packed))[0..3]
          Faker::Base58.encode(packed + checksum)
        end
      end
    end
  end
end
