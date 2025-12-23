# frozen_string_literal: true

require 'openssl'

module Faker
  class Crypto < Base
    class << self
      ##
      # Produces an MD5 hash.
      #
      # @return [String]
      #
      # @example
      #   Faker::Crypto.md5 #=> "6b5ed240042e8a65c55ddb826c3408e6"
      #
      # @faker.version 1.6.4
      def md5
        OpenSSL::Digest::MD5.hexdigest(Lorem.characters)
      end

      ##
      # Produces a SHA1 hash.
      #
      # @return [String]
      #
      # @example
      #   Faker::Crypto.sha1 #=> "4e99e31c51eef8b2d290e709f757f92e558a503f"
      #
      # @faker.version 1.6.4
      def sha1
        OpenSSL::Digest::SHA1.hexdigest(Lorem.characters)
      end

      ##
      # Produces a SHA256 hash.
      #
      # @return [String]
      #
      # @example
      #   Faker::Crypto.sha256 #=> "51e4dbb424cd9db1ec5fb989514f2a35652ececef33f21c8dd1fd61bb8e3929d"
      #
      # @faker.version 1.6.4
      def sha256
        OpenSSL::Digest::SHA256.hexdigest(Lorem.characters)
      end

      ##
      # Produces a SHA512 hash.
      #
      # @return [String]
      #
      # @example
      #   Faker::Crypto.sha512 #=> "7b9fc82a6642874833d01b74a7b4fae3d15373193b55cfba47327f8f0afdc8d0ea155b58639a03a887009ef997dab8dd8d36767620d430f6e787e5996e26da80"
      #
      # @faker.version next
      def sha512
        OpenSSL::Digest::SHA512.hexdigest(Lorem.characters)
      end
    end
  end
end
