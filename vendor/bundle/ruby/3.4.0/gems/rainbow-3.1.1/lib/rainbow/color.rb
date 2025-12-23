# frozen_string_literal: true

module Rainbow
  class Color
    attr_reader :ground

    def self.build(ground, values)
      unless [1, 3].include?(values.size)
        raise ArgumentError,
              "Wrong number of arguments for color definition, should be 1 or 3"
      end

      color = values.size == 1 ? values.first : values

      case color
      # NOTE: Properly handle versions before/after Ruby 2.4.0.
      # Ruby 2.4+ unifies Fixnum & Bignum into Integer.
      # However previous versions would still use Fixnum.
      # To avoid missing `Fixnum` input, call `0.class` which would
      # return either `Integer` or `Fixnum`.
      when 0.class
        Indexed.new(ground, color)
      when Symbol
        if Named.color_names.include?(color)
          Named.new(ground, color)
        elsif X11Named.color_names.include?(color)
          X11Named.new(ground, color)
        else
          raise ArgumentError,
                "Unknown color name, valid names: " +
                (Named.color_names + X11Named.color_names).join(', ')
        end
      when Array
        RGB.new(ground, *color)
      when String
        RGB.new(ground, *parse_hex_color(color))
      end
    end

    def self.parse_hex_color(hex)
      unless hex =~ /^#?[a-f0-9]{6}/i
        raise ArgumentError,
              "Invalid hexadecimal RGB triplet. Valid format: /^#?[a-f0-9]{6}/i"
      end

      hex = hex.sub(/^#/, '')
      r   = hex[0..1].to_i(16)
      g   = hex[2..3].to_i(16)
      b   = hex[4..5].to_i(16)

      [r, g, b]
    end

    class Indexed < Color
      attr_reader :num

      def initialize(ground, num)
        @ground = ground
        @num = num
      end

      def codes
        code = num + (ground == :foreground ? 30 : 40)

        [code]
      end
    end

    class Named < Indexed
      NAMES = {
        black: 0,
        red: 1,
        green: 2,
        yellow: 3,
        blue: 4,
        magenta: 5,
        cyan: 6,
        white: 7,
        default: 9
      }.freeze

      def self.color_names
        NAMES.keys
      end

      def self.valid_names
        color_names.join(', ')
      end

      def initialize(ground, name)
        unless Named.color_names.include?(name)
          raise ArgumentError,
                "Unknown color name, valid names: #{self.class.valid_names}"
        end

        super(ground, NAMES[name])
      end
    end

    class RGB < Indexed
      attr_reader :r, :g, :b

      def self.to_ansi_domain(value)
        (6 * (value / 256.0)).to_i
      end

      def initialize(ground, *values)
        if values.min.negative? || values.max > 255
          raise ArgumentError, "RGB value outside 0-255 range"
        end

        super(ground, 8)
        @r, @g, @b = values
      end

      def codes
        super + [5, code_from_rgb]
      end

      private

      def code_from_rgb
        16 + self.class.to_ansi_domain(r) * 36 +
          self.class.to_ansi_domain(g) * 6 +
          self.class.to_ansi_domain(b)
      end
    end

    class X11Named < RGB
      include X11ColorNames

      def self.color_names
        NAMES.keys
      end

      def self.valid_names
        color_names.join(', ')
      end

      def initialize(ground, name)
        unless X11Named.color_names.include?(name)
          raise ArgumentError,
                "Unknown color name, valid names: #{self.class.valid_names}"
        end

        super(ground, *NAMES[name])
      end
    end
  end
end
