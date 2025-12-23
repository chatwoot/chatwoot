# frozen_string_literal: true

module Faker
  class Types < Base
    CHARACTERS = ('0'..'9').to_a + ('a'..'z').to_a
    SIMPLE_TYPES = %i[string fixnum].freeze
    COMPLEX_TYPES = %i[hash array].freeze

    class << self
      ##
      # Produces a random String created from word (Faker::Lorem.word)
      #
      # @return [String]
      #
      # @example
      #   Faker::Types.rb_string #=> "foobar"
      #
      # @faker.version 1.8.6
      def rb_string(words: 1)
        resolved_num = resolve(words)
        word_list =
          translate('faker.lorem.words')

        word_list *= ((resolved_num / word_list.length) + 1)
        shuffle(word_list)[0, resolved_num].join(' ')
      end

      ##
      # Produces a random character from the a-z, 0-9 ranges.
      #
      # @return [String]
      #
      # @example
      #   Faker::Types.character #=> "n"
      #
      # @faker.version 1.8.6
      def character
        sample(CHARACTERS)
      end

      ##
      # Produces a random integer.
      #
      # @return [Integer]
      #
      # @example
      #   Faker::Types.rb_integer #=> 1
      #
      # @faker.version 1.8.6
      def rb_integer(from: 0, to: 100)
        rand(from..to).to_i
      end

      ##
      # Produces a random hash with random keys and values.
      #
      # @param number [Integer] Specifies the number of key-value pairs.
      # @return [Hash]
      #
      # @example
      #   Faker::Types.rb_hash #=> {name: "bob"}
      #   Faker::Types.rb_hash(number: 1) #=> {name: "bob"}
      #   Faker::Types.rb_hash(number: 2) #=> {name: "bob", last: "marley"}
      #
      # @faker.version 1.8.6
      def rb_hash(number: 1, type: -> { random_type })
        {}.tap do |hsh|
          Lorem.words(number: number * 2).uniq.first(number).each do |s|
            value = type.is_a?(Proc) ? type.call : type
            hsh.merge!(s.to_sym => value)
          end
        end
      end

      ##
      # Produces a random complex hash with random keys and values where the values may include other hashes and arrays.
      #
      # @param number [Integer] Specifies the number of key-value pairs.
      # @return [Hash]
      #
      # @example
      #   Faker::Types.complex_rb_hash #=> {user: {first: "bob", last: "marley"}}
      #   Faker::Types.complex_rb_hash(number: 1) #=> {user: {first: "bob", last: "marley"}}
      #   Faker::Types.complex_rb_hash(number: 2) #=> {user: {first: "bob", last: "marley"}, son: ["damien", "marley"]}
      #
      # @faker.version 1.8.6
      def complex_rb_hash(number: 1)
        rb_hash(number: number, type: -> { random_complex_type })
      end

      ##
      # Produces a random array.
      #
      # @param len [Integer] Specifies the number of elements in the array.
      # @return [Array]
      #
      # @example
      #   Faker::Types.rb_array #=> ["a"]
      #   Faker::Types.rb_array(len: 4) #=> ["a", 1, 2, "bob"]
      #
      # @faker.version 1.8.6
      def rb_array(len: 1)
        [].tap do |ar|
          len.times do
            ar.push random_type
          end
        end
      end

      ##
      # Produces a random type that's either a String or an Integer.
      #
      # @return [String, Integer]
      #
      # @example
      #   Faker::Types.random_type #=> 1 or "a" or "bob"
      #
      # @faker.version 1.8.6
      def random_type
        type_to_use = SIMPLE_TYPES[rand(0..SIMPLE_TYPES.length - 1)]
        case type_to_use
        when :string
          rb_string
        when :fixnum
          rb_integer
        end
      end

      ##
      # Produces a random complex type that's either a String, an Integer, an array or a hash.
      #
      # @return [String, Integer]
      #
      # @example
      #   Faker::Types.random_complex_type #=> 1 or "a" or "bob" or {foo: "bar"}
      #
      # @faker.version 1.8.6
      def random_complex_type
        types = SIMPLE_TYPES + COMPLEX_TYPES
        type_to_use = types[rand(0..types.length - 1)]
        case type_to_use
        when :string
          rb_string
        when :fixnum
          rb_integer
        when :hash
          rb_hash
        when :array
          rb_array
        end
      end

      private

      def titleize(word)
        word.split(/(\W)/).map(&:capitalize).join
      end
    end
  end
end
