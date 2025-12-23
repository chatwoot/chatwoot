# frozen_string_literal: true

module Faker
  class Source < Base
    class << self
      ##
      # Produces source code for Hello World in a given language.
      #
      # @param lang [Symbol] The programming language to use
      # @return [String]
      #
      # @example
      #   Faker::Source.hello_world #=> "puts 'Hello World!'"
      #
      # @example
      #   Faker::Source.hello_world(lang: :javascript)
      #     #=> "alert('Hello World!');"
      #
      # @faker.version 1.9.0
      def hello_world(lang: :ruby)
        fetch("source.hello_world.#{lang}")
      end

      ##
      # Produces source code for printing a string in a given language.
      #
      # @param str [String] The string to print
      # @param lang [Symbol] The programming language to use
      # @return [String]
      #
      # @example
      #   Faker::Source.print #=> "puts 'faker_string_to_print'"
      # @example
      #   Faker::Source.print(str: 'foo bar', lang: :javascript)
      #     #=> "console.log('foo bar');"
      #
      # @faker.version 1.9.0
      def print(str: 'some string', lang: :ruby)
        code = fetch("source.print.#{lang}")
        code.gsub('faker_string_to_print', str)
      end

      ##
      # Produces source code for printing 1 through 10 in a given language.
      #
      # @param lang [Symbol] The programming language to use
      # @return [String]
      #
      # @example
      #   Faker::Source.print_1_to_10 #=> "(1..10).each { |i| puts i }"
      # @example
      #   Faker::Source.print_1_to_10(lang: :javascript)
      #   # => "for (let i=0; i<10; i++) {
      #   #       console.log(i);
      #   #    }"
      #
      # @faker.version 1.9.0
      def print_1_to_10(lang: :ruby)
        fetch("source.print_1_to_10.#{lang}")
      end
    end
  end
end
