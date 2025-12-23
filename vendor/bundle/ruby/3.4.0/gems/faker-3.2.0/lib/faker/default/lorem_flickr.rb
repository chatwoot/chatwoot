# frozen_string_literal: true

module Faker
  class LoremFlickr < Base
    class << self
      SUPPORTED_COLORIZATIONS = %w[red green blue].freeze

      ##
      # Produces a random image URL from loremflickr.com.
      #
      # @param size [String] Specifies the size of image to generate.
      # @param search_terms [Array<String>] Adds search terms to the image URL.
      # @param match_all [Boolean] Add "all" as part of the URL.
      # @return [String]
      #
      # @example
      #   Faker::LoremFlickr.image #=> "https://loremflickr.com/300/300"
      #   Faker::LoremFlickr.image(size: "50x60") #=> "https://loremflickr.com/50/60"
      #   Faker::LoremFlickr.image(size: "50x60", search_terms: ['sports']) #=> "https://loremflickr.com/50/60/sports"
      #   Faker::LoremFlickr.image(size: "50x60", search_terms: ['sports', 'fitness']) #=> "https://loremflickr.com/50/60/sports,fitness"
      #   Faker::LoremFlickr.image(size: "50x60", search_terms: ['sports', 'fitness'], match_all: true) #=> "https://loremflickr.com/50/60/sports,fitness/all"
      #
      # @faker.version 1.9.0
      def image(size: '300x300', search_terms: [], match_all: false)
        build_url(size, nil, search_terms, match_all)
      end

      ##
      # Produces a random grayscale image URL from loremflickr.com.
      #
      # @param size [String] Specifies the size of image to generate.
      # @param search_terms [Array<String>] Adds search terms to the image URL.
      # @param match_all [Boolean] Add "all" as part of the URL.
      # @return [String]
      #
      # @example
      #   Faker::LoremFlickr.grayscale_image #=> "https://loremflickr.com/g/300/300/all"
      #   Faker::LoremFlickr.grayscale_image(size: "50x60") #=> "https://loremflickr.com/g/50/60/all"
      #   Faker::LoremFlickr.grayscale_image(size: "50x60", search_terms: ['sports']) #=> "https://loremflickr.com/g/50/60/sports"
      #   Faker::LoremFlickr.grayscale_image(size: "50x60", search_terms: ['sports', 'fitness']) #=> "https://loremflickr.com/50/60/g/sports,fitness"
      #   Faker::LoremFlickr.grayscale_image(size: "50x60", search_terms: ['sports', 'fitness'], match_all: true) #=> "https://loremflickr.com/g/50/60/sports,fitness/all"
      #
      # @faker.version 1.9.0
      def grayscale_image(size: '300x300', search_terms: ['all'], match_all: false)
        raise ArgumentError, 'Search terms must be specified for grayscale images' unless search_terms.any?

        build_url(size, 'g', search_terms, match_all)
      end

      ##
      # Produces a random pixelated image URL from loremflickr.com.
      #
      # @param size [String] Specifies the size of image to generate.
      # @param search_terms [Array<String>] Adds search terms to the image URL.
      # @param match_all [Boolean] Add "all" as part of the URL.
      # @return [String]
      #
      # @example
      #   Faker::LoremFlickr.pixelated_image #=> "https://loremflickr.com/p/300/300/all"
      #   Faker::LoremFlickr.pixelated_image(size: "50x60") #=> "https://loremflickr.com/p/50/60/all"
      #   Faker::LoremFlickr.pixelated_image(size: "50x60", search_terms: ['sports']) #=> "https://loremflickr.com/p/50/60/sports"
      #   Faker::LoremFlickr.pixelated_image(size: "50x60", search_terms: ['sports', 'fitness']) #=> "https://loremflickr.com/p/50/60/sports,fitness"
      #   Faker::LoremFlickr.pixelated_image(size: "50x60", search_terms: ['sports', 'fitness'], match_all: true) #=> "https://loremflickr.com/p/50/60/sports,fitness/all"
      #
      # @faker.version 1.9.0
      def pixelated_image(size: '300x300', search_terms: ['all'], match_all: false)
        raise ArgumentError, 'Search terms must be specified for pixelated images' unless search_terms.any?

        build_url(size, 'p', search_terms, match_all)
      end

      ##
      # Produces a random colorized image URL from loremflickr.com.
      #
      # @param size [String] Specifies the size of image to generate.
      # @param color [String] Specifies the color of image to generate.
      # @param search_terms [Array<String>] Adds search terms to the image URL.
      # @param match_all [Boolean] Add "all" as part of the URL.
      # @return [String]
      #
      # @example
      #   Faker::LoremFlickr.image #=> "https://loremflickr.com/red/300/300/all"
      #   Faker::LoremFlickr.image(size: "50x60", color: 'blue') #=> "https://loremflickr.com/blue/50/60/all"
      #   Faker::LoremFlickr.image(size: "50x60", color: 'blue', search_terms: ['sports']) #=> "https://loremflickr.com/blue/50/60/sports"
      #   Faker::LoremFlickr.image(size: "50x60", color: 'blue', search_terms: ['sports', 'fitness']) #=> "https://loremflickr.com/blue/50/60/sports,fitness"
      #   Faker::LoremFlickr.image(size: "50x60", color: 'blue', search_terms: ['sports', 'fitness'], match_all: true) #=> "https://loremflickr.com/blue/50/60/sports,fitness/all"
      #
      # @faker.version 1.9.0
      def colorized_image(size: '300x300', color: 'red', search_terms: ['all'], match_all: false)
        raise ArgumentError, 'Search terms must be specified for colorized images' unless search_terms.any?
        raise ArgumentError, "Supported colorizations are #{SUPPORTED_COLORIZATIONS.join(', ')}" unless SUPPORTED_COLORIZATIONS.include?(color)

        build_url(size, color, search_terms, match_all)
      end

      private

      def build_url(size, format, search_terms, match_all)
        raise ArgumentError, 'Size should be specified in format 300x300' unless size =~ /^[0-9]+x[0-9]+$/

        url_parts = ['https://loremflickr.com']
        url_parts << format
        url_parts += size.split('x')
        url_parts << search_terms.compact.join(',') if search_terms.any?
        url_parts << 'all' if match_all
        url_parts.compact.join('/')
      end
    end
  end
end
