# frozen_string_literal: true

module Faker
  class Quote < Base
    class << self
      ##
      # Produces a famous last words quote.
      #
      # @return [String]
      #
      # @example
      #   Faker::Quote.famous_last_words #=> "My vocabulary did this to me. Your love will let you go on..."
      #
      # @faker.version 1.9.0
      def famous_last_words
        fetch('quote.famous_last_words')
      end

      ##
      # Produces a quote from Deep Thoughts by Jack Handey.
      #
      # @return [String]
      #
      # @example
      #   Faker::Quote.jack_handey # => "I hope life isn't a big joke, because I don't get it."
      #
      # @faker.version next
      def jack_handey
        fetch('quote.jack_handey')
      end

      ##
      # Produces a quote from Matz.
      #
      # @return [String]
      #
      # @example
      #   Faker::Quote.matz #=> "You want to enjoy life, don't you? If you get your job done quickly and your job is fun, that's good isn't it? That's the purpose of life, partly. Your life is better."
      #
      # @faker.version 1.9.0
      def matz
        fetch('quote.matz')
      end

      ##
      # Produces a quote about the most interesting man in the world.
      #
      # @return [String]
      #
      # @example
      #   Faker::Quote.most_interesting_man_in_the_world #=> "He can speak Russian... in French"
      #
      # @faker.version 1.9.0
      def most_interesting_man_in_the_world
        fetch('quote.most_interesting_man_in_the_world')
      end

      ##
      # Produces a Robin quote.
      #
      # @return [String]
      #
      # @example
      #   Faker::Quote.robin #=> "Holy Razors Edge"
      #
      # @faker.version 1.9.0
      def robin
        fetch('quote.robin')
      end

      ##
      # Produces a singular siegler quote.
      #
      # @return [String]
      #
      # @example
      #   Faker::Quote.singular_siegler #=> "Texas!"
      #
      # @faker.version 1.9.0
      def singular_siegler
        fetch('quote.singular_siegler')
      end

      ##
      # Produces a quote from Yoda.
      #
      # @return [String]
      #
      # @example
      #   Faker::Quote.yoda #=> "Use your feelings, Obi-Wan, and find him you will."
      #
      # @faker.version 1.9.0
      def yoda
        fetch('quote.yoda')
      end

      ##
      # Produces a quote from a fortune cookie.
      #
      # @return [String]
      #
      # @example
      #   Faker::Quote.fortune_cookie #=> "This cookie senses that you are superstitious; it is an inclination that is bad for your mental health."
      #
      # @faker.version next
      def fortune_cookie
        fetch('quote.fortune_cookie')
      end

      ##
      # Produces a quote from comedian Mitch Hedberg.
      #
      # @return [String]
      #
      # @example
      #   Faker::Quote.mitch_hedberg # => "I like Kit-Kats, unless I'm with four or more people."
      #
      # @faker.version next
      def mitch_hedberg
        fetch('quote.mitch_hedberg')
      end
    end
  end
end
