# frozen_string_literal: true

module Faker
  class CryptoCoin < Base
    class << self
      COIN_NAME = 0
      ACRONYM = 1
      URL_LOGO = 2

      ##
      # Produces a random crypto coin name.
      #
      # @return [String]
      #
      # @example
      #   Faker::CryptoCoin.coin_name #=> "Bitcoin"
      #
      # @faker.version 1.9.2
      def coin_name(coin: coin_array)
        coin[COIN_NAME]
      end

      ##
      # Produces a random crypto coin acronym.
      #
      # @return [String]
      #
      # @example
      #   Faker::CryptoCoin.acronym #=> "BTC"
      #
      # @faker.version 1.9.2
      def acronym(coin: coin_array)
        coin[ACRONYM]
      end

      ##
      # Produces a random crypto coin logo url.
      #
      # @return [String]
      #
      # @example
      #   Faker::CryptoCoin.url_logo #=> "https://i.imgur.com/EFz61Ei.png"
      #
      # @faker.version 1.9.2
      def url_logo(coin: coin_array)
        coin[URL_LOGO]
      end

      ##
      # Produces a random crypto coin's name, acronym and logo in an array.
      #
      # @return [Array<String>]
      #
      # @example
      #   Faker::CryptoCoin.coin_array #=> ["Dash", "DASH", "https://i.imgur.com/2uX91cb.png"]
      #
      # @faker.version 1.9.2
      def coin_array
        fetch('crypto_coin.coin').split(',').map(&:strip)
      end

      ##
      # Produces a random crypto coin's name, acronym and logo in a hash.
      #
      # @return [Hash]
      #
      # @example
      #   Faker::CryptoCoin.coin_hash {:name=>"Ethereum", :acronym=>"ETH", :url_logo=>"https://i.imgur.com/uOPFCXj.png"}
      #
      # @faker.version 1.9.2
      def coin_hash
        coin = coin_array

        {
          name: coin_name(coin: coin),
          acronym: acronym(coin: coin),
          url_logo: url_logo(coin: coin)
        }
      end
    end
  end
end
