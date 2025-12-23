# frozen_string_literal: true

module Faker
  class String < Base
    class << self
      ##
      # Produces a random UTF-8 string with optional nested length selectors.
      #
      # @param length [Integer, Range, Array<Integer, Range, nil>] The length of produced string and/or specific UTF-8 characters to use.
      # @return [String]
      #
      # @example
      #   Faker::String.random #=> "3 뇦\u0017&y\u{3A109}$8^4* 녹豿4좘툢ꔾ쉙6ɉ\uA6 8TN畀챵|\"3쇤Ŵ"
      #   Faker::String.random(length: 4) #=> "⼨%0*"
      #   Faker::String.random(length: 3..12) #=> "\u{69FDC};秨툫"
      #   Faker::String.random(length: [0, 6]) #=> "I轤𣴒P溟L"
      #   Faker::String.random(length: [1, (2..5), [3, 6], nil]) #=> "葓L#ћ"
      #
      # @faker.version 1.9.0
      def random(length: 32)
        utf8string select_a length
      end

      private

      def select_a(length)
        if length.class.included_modules.include? Enumerable
          select_a sample(length.to_enum.to_a)
        else
          length # recursive base case
        end
      end

      def utf8string(length)
        ratio = char_space_ratio
        (1..length.to_i).map do
          space_or_utf8_char ratio
        end.join
      end

      def space_or_utf8_char(ratio)
        sample [32.chr(Encoding::UTF_8), [utf8character] * ratio].flatten
      end

      def char_space_ratio
        sample [2, [3] * 5, [5] * 17, [7] * 11, 11, 191].flatten
      end

      def utf8character
        sample([
                 rand(32..90),           # latin alphabet
                 rand(128),              # 7-bit ASCII
                 rand(0xd800),           # utf-8 codepoints below utf-16 surrogate halves
                 rand(57_344..1_114_111) # utf-8 codepoints above utf-16 surrogate halves
               ]).chr(Encoding::UTF_8)
      end
    end
  end
end
