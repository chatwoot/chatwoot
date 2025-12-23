# frozen_string_literal: true

module Faker
  class Placeholdit < Base
    class << self
      SUPPORTED_FORMATS = %w[png jpg gif jpeg].freeze

      ##
      # Produces a random placeholder image from https://via.placeholder.com.
      #
      # @param size [String] Specifies the image's size, dimensions separated by 'x'.
      # @param format [String] Specifies the image's extension.
      # @param background_color [String, Symbol] Specifies the background color, either in hexadecimal format (without #) or as :random.
      # @param text_color [String, Symbol] Specifies the text color, either in hexadecimal format (without #) or as :random.
      # @param text [String] Specifies a custom text to be used.
      # @return [String]
      #
      # @example
      #     # Keyword arguments: size, format, background_color, text_color, text
      #   Faker::Placeholdit.image #=> "https://via.placeholder.com/300x300.png"
      #   Faker::Placeholdit.image(size: '50x50') #=> "https://via.placeholder.com/50x50.png"
      #   Faker::Placeholdit.image(size: '50x50', format: 'jpg') #=> "https://via.placeholder.com/50x50.jpg"
      #   Faker::Placeholdit.image(size: '50x50', format: 'gif', background_color: 'ffffff') #=> "https://via.placeholder.com/50x50.gif/ffffff"
      #   Faker::Placeholdit.image(size: '50x50', format: 'jpeg', background_color: :random) #=> "https://via.placeholder.com/50x50.jpeg/39eba7"
      #   Faker::Placeholdit.image(size: '50x50', format: 'jpeg', background_color: 'ffffff', text_color: '000') #=> "https://via.placeholder.com/50x50.jpeg/ffffff/000"
      #   Faker::Placeholdit.image(size: '50x50', format: 'jpg', background_color: 'ffffff', text_color: '000', text: 'Some Custom Text') #=> "https://via.placeholder.com/50x50.jpg/ffffff/000?text=Some Custom Text"
      #
      # @faker.version 1.6.0
      def image(size: '300x300', format: 'png', background_color: nil, text_color: nil, text: nil)
        background_color = generate_color if background_color == :random
        text_color = generate_color if text_color == :random

        raise ArgumentError, 'Size should be specified in format 300x300' unless size =~ /^[0-9]+x[0-9]+$/
        raise ArgumentError, "Supported formats are #{SUPPORTED_FORMATS.join(', ')}" unless SUPPORTED_FORMATS.include?(format)
        raise ArgumentError, "background_color must be a hex value without '#'" unless background_color.nil? || background_color =~ /((?:^\h{3}$)|(?:^\h{6}$)){1}(?!.*\H)/
        raise ArgumentError, "text_color must be a hex value without '#'" unless text_color.nil? || text_color =~ /((?:^\h{3}$)|(?:^\h{6}$)){1}(?!.*\H)/

        image_url = "https://via.placeholder.com/#{size}.#{format}"
        image_url += "/#{background_color}" if background_color
        image_url += "/#{text_color}" if text_color
        image_url += "?text=#{text}" if text
        image_url
      end

      private

      def generate_color
        format('%06x', (rand * 0xffffff))
      end
    end
  end
end
