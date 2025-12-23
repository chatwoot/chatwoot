# frozen_string_literal: true

module Faker
  class NatoPhoneticAlphabet < Base
    class << self
      ##
      # Produces a code word from the NATO phonetic alphabet.
      #
      # @return [String]
      #
      # @example
      #   Faker::NatoPhoneticAlphabet.code_word #=> "Hotel"
      #
      # @faker.version 1.9.0
      def code_word
        fetch('nato_phonetic_alphabet.code_word')
      end
    end
  end
end
