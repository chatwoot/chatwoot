# frozen_string_literal: true

module Faker
  class Color < Base
    class << self
      LIGHTNESS_LOOKUP = {
        light: 0.8,
        dark: 0.2
      }.freeze
      ##
      # Produces a hex color code.
      # Clients are able to specify the hue, saturation, or lightness of the required color.
      # Alternatively a client can simply specify that they need a light or dark color.
      #
      # @param args [Hash, Symbol] Allows the client to specify what color should be return
      #
      # @return [String]
      #
      # @example
      #   Faker::Color.hex_color #=> "#31a785"
      # @example
      #   Faker::Color.hex_color(hue: 118, saturation: 1, lightness: 0.53) #=> "#048700"
      # @example
      #   Faker::Color.hex_color(:light) #=> "#FFEE99"
      # @example
      #   Faker::Color.hex_color(:dark) #=> "#665500"
      #
      # @faker.version next
      def hex_color(args = nil)
        hsl_hash = {}
        hsl_hash = { lightness: LIGHTNESS_LOOKUP[args] } if %i[dark light].include?(args)
        hsl_hash = args if args.is_a?(Hash)
        hsl_to_hex(hsl_color(**hsl_hash))
      end

      ##
      # Produces the name of a color.
      #
      # @return [String]
      #
      # @example
      #   Faker::Color.color_name #=> "yellow"
      #
      # @faker.version 1.6.2
      def color_name
        fetch('color.name')
      end

      # @private
      def single_rgb_color
        sample((0..255).to_a)
      end

      ##
      # Produces an array of integers representing an RGB color.
      #
      # @return [Array(Integer, Integer, Integer)]
      #
      # @example
      #   Faker::Color.rgb_color #=> [54, 233, 67]
      #
      # @faker.version 1.5.0
      def rgb_color
        Array.new(3) { single_rgb_color }
      end

      ##
      # Produces an array of floats representing an HSL color.
      # The array is in the form of `[hue, saturation, lightness]`.
      #
      # @param hue [FLoat] Optional value to use for hue
      # @param saturation [Float] Optional value to use for saturation
      # @param lightness [Float] Optional value to use for lightness
      # @return [Array(Float, Float, Float)]
      #
      # @example
      #   Faker::Color.hsl_color #=> [69.87, 0.66, 0.3]
      # @example
      #   Faker::Color.hsl_color(hue: 70, saturation: 0.5, lightness: 0.8) #=> [70, 0.5, 0.8]
      # @example
      #   Faker::Color.hsl_color(hue: 70) #=> [70, 0.66, 0.6]
      # @example
      #   Faker::Color.hsl_color(saturation: 0.2) #=> [54, 0.2, 0.3]
      # @example
      #   Faker::Color.hsl_color(lightness: 0.6) #=> [69.87, 0.66, 0.6]
      #
      # @faker.version next
      def hsl_color(hue: nil, saturation: nil, lightness: nil)
        valid_hue = hue || sample((0..360).to_a)
        valid_saturation = saturation&.clamp(0, 1) || rand.round(2)
        valid_lightness = lightness&.clamp(0, 1) || rand.round(2)
        [valid_hue, valid_saturation, valid_lightness]
      end

      ##
      # Produces an array of floats representing an HSLA color.
      # The array is in the form of `[hue, saturation, lightness, alpha]`.
      #
      # @return [Array(Float, Float, Float, Float)]
      #
      # @example
      #   Faker::Color.hsla_color #=> [154.77, 0.36, 0.9, 0.2]
      #
      # @faker.version 1.5.0
      def hsla_color
        hsl_color << rand.round(1)
      end

      private

      ##
      # Produces a hex code representation of an HSL color
      #
      # @param a_hsl_color [Array(Float, Float, Float)] The array that represents the HSL color
      #
      # @return [String]
      #
      # @example
      #   hsl_to_hex([50, 100,80]) #=> #FFEE99
      #
      # @see https://en.wikipedia.org/wiki/HSL_and_HSV#HSL_to_RGB
      # @see https://github.com/jpmckinney/color-generator/blob/master/lib/color-generator.rb
      #
      def hsl_to_hex(a_hsl_color)
        h, s, l = a_hsl_color
        c = (1 - (2 * l - 1).abs) * s
        h_prime = h / 60
        x = c * (1 - (h_prime % 2 - 1).abs)
        m = l - 0.5 * c

        rgb = case h_prime.to_i
              when 0 # 0 <= H' < 1
                [c, x, 0]
              when 1 # 1 <= H' < 2
                [x, c, 0]
              when 2 # 2 <= H' < 3
                [0, c, x]
              when 3 # 3 <= H' < 4
                [0, x, c]
              when 4 # 4 <= H' < 5
                [x, 0, c]
              else # 5 <= H' < 6
                [c, 0, x]
              end.map { |value| ((value + m) * 255).round }

        format('#%02x%02x%02x', rgb[0], rgb[1], rgb[2])
      end
    end
  end
end
