module Sass::Script::Value
  # A SassScript object representing a CSS color.
  #
  # A color may be represented internally as RGBA, HSLA, or both.
  # It's originally represented as whatever its input is;
  # if it's created with RGB values, it's represented as RGBA,
  # and if it's created with HSL values, it's represented as HSLA.
  # Once a property is accessed that requires the other representation --
  # for example, \{#red} for an HSL color --
  # that component is calculated and cached.
  #
  # The alpha channel of a color is independent of its RGB or HSL representation.
  # It's always stored, as 1 if nothing else is specified.
  # If only the alpha channel is modified using \{#with},
  # the cached RGB and HSL values are retained.
  class Color < Base
    # @private
    #
    # Convert a ruby integer to a rgba components
    # @param color [Integer]
    # @return [Array<Integer>] Array of 4 numbers representing r,g,b and alpha
    def self.int_to_rgba(color)
      rgba = (0..3).map {|n| color >> (n << 3) & 0xff}.reverse
      rgba[-1] = rgba[-1] / 255.0
      rgba
    end

    ALTERNATE_COLOR_NAMES = Sass::Util.map_vals(
      {
        'aqua'                 => 0x00FFFFFF,
        'darkgrey'             => 0xA9A9A9FF,
        'darkslategrey'        => 0x2F4F4FFF,
        'dimgrey'              => 0x696969FF,
        'fuchsia'              => 0xFF00FFFF,
        'grey'                 => 0x808080FF,
        'lightgrey'            => 0xD3D3D3FF,
        'lightslategrey'       => 0x778899FF,
        'slategrey'            => 0x708090FF,
      }, &method(:int_to_rgba))

    # A hash from color names to `[red, green, blue]` value arrays.
    COLOR_NAMES = Sass::Util.map_vals(
      {
        'aliceblue'            => 0xF0F8FFFF,
        'antiquewhite'         => 0xFAEBD7FF,
        'aquamarine'           => 0x7FFFD4FF,
        'azure'                => 0xF0FFFFFF,
        'beige'                => 0xF5F5DCFF,
        'bisque'               => 0xFFE4C4FF,
        'black'                => 0x000000FF,
        'blanchedalmond'       => 0xFFEBCDFF,
        'blue'                 => 0x0000FFFF,
        'blueviolet'           => 0x8A2BE2FF,
        'brown'                => 0xA52A2AFF,
        'burlywood'            => 0xDEB887FF,
        'cadetblue'            => 0x5F9EA0FF,
        'chartreuse'           => 0x7FFF00FF,
        'chocolate'            => 0xD2691EFF,
        'coral'                => 0xFF7F50FF,
        'cornflowerblue'       => 0x6495EDFF,
        'cornsilk'             => 0xFFF8DCFF,
        'crimson'              => 0xDC143CFF,
        'cyan'                 => 0x00FFFFFF,
        'darkblue'             => 0x00008BFF,
        'darkcyan'             => 0x008B8BFF,
        'darkgoldenrod'        => 0xB8860BFF,
        'darkgray'             => 0xA9A9A9FF,
        'darkgreen'            => 0x006400FF,
        'darkkhaki'            => 0xBDB76BFF,
        'darkmagenta'          => 0x8B008BFF,
        'darkolivegreen'       => 0x556B2FFF,
        'darkorange'           => 0xFF8C00FF,
        'darkorchid'           => 0x9932CCFF,
        'darkred'              => 0x8B0000FF,
        'darksalmon'           => 0xE9967AFF,
        'darkseagreen'         => 0x8FBC8FFF,
        'darkslateblue'        => 0x483D8BFF,
        'darkslategray'        => 0x2F4F4FFF,
        'darkturquoise'        => 0x00CED1FF,
        'darkviolet'           => 0x9400D3FF,
        'deeppink'             => 0xFF1493FF,
        'deepskyblue'          => 0x00BFFFFF,
        'dimgray'              => 0x696969FF,
        'dodgerblue'           => 0x1E90FFFF,
        'firebrick'            => 0xB22222FF,
        'floralwhite'          => 0xFFFAF0FF,
        'forestgreen'          => 0x228B22FF,
        'gainsboro'            => 0xDCDCDCFF,
        'ghostwhite'           => 0xF8F8FFFF,
        'gold'                 => 0xFFD700FF,
        'goldenrod'            => 0xDAA520FF,
        'gray'                 => 0x808080FF,
        'green'                => 0x008000FF,
        'greenyellow'          => 0xADFF2FFF,
        'honeydew'             => 0xF0FFF0FF,
        'hotpink'              => 0xFF69B4FF,
        'indianred'            => 0xCD5C5CFF,
        'indigo'               => 0x4B0082FF,
        'ivory'                => 0xFFFFF0FF,
        'khaki'                => 0xF0E68CFF,
        'lavender'             => 0xE6E6FAFF,
        'lavenderblush'        => 0xFFF0F5FF,
        'lawngreen'            => 0x7CFC00FF,
        'lemonchiffon'         => 0xFFFACDFF,
        'lightblue'            => 0xADD8E6FF,
        'lightcoral'           => 0xF08080FF,
        'lightcyan'            => 0xE0FFFFFF,
        'lightgoldenrodyellow' => 0xFAFAD2FF,
        'lightgreen'           => 0x90EE90FF,
        'lightgray'            => 0xD3D3D3FF,
        'lightpink'            => 0xFFB6C1FF,
        'lightsalmon'          => 0xFFA07AFF,
        'lightseagreen'        => 0x20B2AAFF,
        'lightskyblue'         => 0x87CEFAFF,
        'lightslategray'       => 0x778899FF,
        'lightsteelblue'       => 0xB0C4DEFF,
        'lightyellow'          => 0xFFFFE0FF,
        'lime'                 => 0x00FF00FF,
        'limegreen'            => 0x32CD32FF,
        'linen'                => 0xFAF0E6FF,
        'magenta'              => 0xFF00FFFF,
        'maroon'               => 0x800000FF,
        'mediumaquamarine'     => 0x66CDAAFF,
        'mediumblue'           => 0x0000CDFF,
        'mediumorchid'         => 0xBA55D3FF,
        'mediumpurple'         => 0x9370DBFF,
        'mediumseagreen'       => 0x3CB371FF,
        'mediumslateblue'      => 0x7B68EEFF,
        'mediumspringgreen'    => 0x00FA9AFF,
        'mediumturquoise'      => 0x48D1CCFF,
        'mediumvioletred'      => 0xC71585FF,
        'midnightblue'         => 0x191970FF,
        'mintcream'            => 0xF5FFFAFF,
        'mistyrose'            => 0xFFE4E1FF,
        'moccasin'             => 0xFFE4B5FF,
        'navajowhite'          => 0xFFDEADFF,
        'navy'                 => 0x000080FF,
        'oldlace'              => 0xFDF5E6FF,
        'olive'                => 0x808000FF,
        'olivedrab'            => 0x6B8E23FF,
        'orange'               => 0xFFA500FF,
        'orangered'            => 0xFF4500FF,
        'orchid'               => 0xDA70D6FF,
        'palegoldenrod'        => 0xEEE8AAFF,
        'palegreen'            => 0x98FB98FF,
        'paleturquoise'        => 0xAFEEEEFF,
        'palevioletred'        => 0xDB7093FF,
        'papayawhip'           => 0xFFEFD5FF,
        'peachpuff'            => 0xFFDAB9FF,
        'peru'                 => 0xCD853FFF,
        'pink'                 => 0xFFC0CBFF,
        'plum'                 => 0xDDA0DDFF,
        'powderblue'           => 0xB0E0E6FF,
        'purple'               => 0x800080FF,
        'red'                  => 0xFF0000FF,
        'rebeccapurple'        => 0x663399FF,
        'rosybrown'            => 0xBC8F8FFF,
        'royalblue'            => 0x4169E1FF,
        'saddlebrown'          => 0x8B4513FF,
        'salmon'               => 0xFA8072FF,
        'sandybrown'           => 0xF4A460FF,
        'seagreen'             => 0x2E8B57FF,
        'seashell'             => 0xFFF5EEFF,
        'sienna'               => 0xA0522DFF,
        'silver'               => 0xC0C0C0FF,
        'skyblue'              => 0x87CEEBFF,
        'slateblue'            => 0x6A5ACDFF,
        'slategray'            => 0x708090FF,
        'snow'                 => 0xFFFAFAFF,
        'springgreen'          => 0x00FF7FFF,
        'steelblue'            => 0x4682B4FF,
        'tan'                  => 0xD2B48CFF,
        'teal'                 => 0x008080FF,
        'thistle'              => 0xD8BFD8FF,
        'tomato'               => 0xFF6347FF,
        'transparent'          => 0x00000000,
        'turquoise'            => 0x40E0D0FF,
        'violet'               => 0xEE82EEFF,
        'wheat'                => 0xF5DEB3FF,
        'white'                => 0xFFFFFFFF,
        'whitesmoke'           => 0xF5F5F5FF,
        'yellow'               => 0xFFFF00FF,
        'yellowgreen'          => 0x9ACD32FF
      }, &method(:int_to_rgba))

    # A hash from `[red, green, blue, alpha]` value arrays to color names.
    COLOR_NAMES_REVERSE = COLOR_NAMES.invert.freeze

    # We add the alternate color names after inverting because
    # different ruby implementations and versions vary on the ordering of the result of invert.
    COLOR_NAMES.update(ALTERNATE_COLOR_NAMES).freeze

    # The user's original representation of the color.
    #
    # @return [String]
    attr_reader :representation

    # Constructs an RGB or HSL color object,
    # optionally with an alpha channel.
    #
    # RGB values are clipped within 0 and 255.
    # Saturation and lightness values are clipped within 0 and 100.
    # The alpha value is clipped within 0 and 1.
    #
    # @raise [Sass::SyntaxError] if any color value isn't in the specified range
    #
    # @overload initialize(attrs)
    #   The attributes are specified as a hash. This hash must contain either
    #   `:hue`, `:saturation`, and `:lightness` keys, or `:red`, `:green`, and
    #   `:blue` keys. It cannot contain both HSL and RGB keys. It may also
    #   optionally contain an `:alpha` key, and a `:representation` key
    #   indicating the original representation of the color that the user wrote
    #   in their stylesheet.
    #
    #   @param attrs [{Symbol => Numeric}] A hash of color attributes to values
    #   @raise [ArgumentError] if not enough attributes are specified,
    #     or both RGB and HSL attributes are specified
    #
    # @overload initialize(rgba, [representation])
    #   The attributes are specified as an array.
    #   This overload only supports RGB or RGBA colors.
    #
    #   @param rgba [Array<Numeric>] A three- or four-element array
    #     of the red, green, blue, and optionally alpha values (respectively)
    #     of the color
    #   @param representation [String] The original representation of the color
    #     that the user wrote in their stylesheet.
    #   @raise [ArgumentError] if not enough attributes are specified
    def initialize(attrs, representation = nil, allow_both_rgb_and_hsl = false)
      super(nil)

      if attrs.is_a?(Array)
        unless (3..4).include?(attrs.size)
          raise ArgumentError.new("Color.new(array) expects a three- or four-element array")
        end

        red, green, blue = attrs[0...3].map {|c| Sass::Util.round(c)}
        @attrs = {:red => red, :green => green, :blue => blue}
        @attrs[:alpha] = attrs[3] ? attrs[3].to_f : 1
        @representation = representation
      else
        attrs = attrs.reject {|_k, v| v.nil?}
        hsl = [:hue, :saturation, :lightness] & attrs.keys
        rgb = [:red, :green, :blue] & attrs.keys
        if !allow_both_rgb_and_hsl && !hsl.empty? && !rgb.empty?
          raise ArgumentError.new("Color.new(hash) may not have both HSL and RGB keys specified")
        elsif hsl.empty? && rgb.empty?
          raise ArgumentError.new("Color.new(hash) must have either HSL or RGB keys specified")
        elsif !hsl.empty? && hsl.size != 3
          raise ArgumentError.new("Color.new(hash) must have all three HSL values specified")
        elsif !rgb.empty? && rgb.size != 3
          raise ArgumentError.new("Color.new(hash) must have all three RGB values specified")
        end

        @attrs = attrs
        @attrs[:hue] %= 360 if @attrs[:hue]
        @attrs[:alpha] ||= 1
        @representation = @attrs.delete(:representation)
      end

      [:red, :green, :blue].each do |k|
        next if @attrs[k].nil?
        @attrs[k] = Sass::Util.restrict(Sass::Util.round(@attrs[k]), 0..255)
      end

      [:saturation, :lightness].each do |k|
        next if @attrs[k].nil?
        @attrs[k] = Sass::Util.restrict(@attrs[k], 0..100)
      end

      @attrs[:alpha] = Sass::Util.restrict(@attrs[:alpha], 0..1)
    end

    # Create a new color from a valid CSS hex string.
    #
    # The leading hash is optional.
    #
    # @return [Color]
    def self.from_hex(hex_string, alpha = nil)
      unless hex_string =~ /^#?([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})?$/i ||
             hex_string =~ /^#?([0-9a-f])([0-9a-f])([0-9a-f])([0-9a-f])?$/i
        raise ArgumentError.new("#{hex_string.inspect} is not a valid hex color.")
      end
      red   = $1.ljust(2, $1).to_i(16)
      green = $2.ljust(2, $2).to_i(16)
      blue  = $3.ljust(2, $3).to_i(16)
      alpha = $4.ljust(2, $4).to_i(16).to_f / 0xff if $4

      hex_string = "##{hex_string}" unless hex_string[0] == ?#
      attrs = {:red => red, :green => green, :blue => blue, :representation => hex_string}
      attrs[:alpha] = alpha if alpha
      new(attrs)
    end

    # The red component of the color.
    #
    # @return [Integer]
    def red
      hsl_to_rgb!
      @attrs[:red]
    end

    # The green component of the color.
    #
    # @return [Integer]
    def green
      hsl_to_rgb!
      @attrs[:green]
    end

    # The blue component of the color.
    #
    # @return [Integer]
    def blue
      hsl_to_rgb!
      @attrs[:blue]
    end

    # The hue component of the color.
    #
    # @return [Numeric]
    def hue
      rgb_to_hsl!
      @attrs[:hue]
    end

    # The saturation component of the color.
    #
    # @return [Numeric]
    def saturation
      rgb_to_hsl!
      @attrs[:saturation]
    end

    # The lightness component of the color.
    #
    # @return [Numeric]
    def lightness
      rgb_to_hsl!
      @attrs[:lightness]
    end

    # The alpha channel (opacity) of the color.
    # This is 1 unless otherwise defined.
    #
    # @return [Integer]
    def alpha
      @attrs[:alpha].to_f
    end

    # Returns whether this color object is translucent;
    # that is, whether the alpha channel is non-1.
    #
    # @return [Boolean]
    def alpha?
      alpha < 1
    end

    # Returns the red, green, and blue components of the color.
    #
    # @return [Array<Integer>] A frozen three-element array of the red, green, and blue
    #   values (respectively) of the color
    def rgb
      [red, green, blue].freeze
    end

    # Returns the red, green, blue, and alpha components of the color.
    #
    # @return [Array<Integer>] A frozen four-element array of the red, green,
    #   blue, and alpha values (respectively) of the color
    def rgba
      [red, green, blue, alpha].freeze
    end

    # Returns the hue, saturation, and lightness components of the color.
    #
    # @return [Array<Integer>] A frozen three-element array of the
    #   hue, saturation, and lightness values (respectively) of the color
    def hsl
      [hue, saturation, lightness].freeze
    end

    # Returns the hue, saturation, lightness, and alpha components of the color.
    #
    # @return [Array<Integer>] A frozen four-element array of the hue,
    #   saturation, lightness, and alpha values (respectively) of the color
    def hsla
      [hue, saturation, lightness, alpha].freeze
    end

    # The SassScript `==` operation.
    # **Note that this returns a {Sass::Script::Value::Bool} object,
    # not a Ruby boolean**.
    #
    # @param other [Value] The right-hand side of the operator
    # @return [Bool] True if this value is the same as the other,
    #   false otherwise
    def eq(other)
      Sass::Script::Value::Bool.new(
        other.is_a?(Color) && rgb == other.rgb && alpha == other.alpha)
    end

    def hash
      [rgb, alpha].hash
    end

    # Returns a copy of this color with one or more channels changed.
    # RGB or HSL colors may be changed, but not both at once.
    #
    # For example:
    #
    #     Color.new([10, 20, 30]).with(:blue => 40)
    #       #=> rgb(10, 40, 30)
    #     Color.new([126, 126, 126]).with(:red => 0, :green => 255)
    #       #=> rgb(0, 255, 126)
    #     Color.new([255, 0, 127]).with(:saturation => 60)
    #       #=> rgb(204, 51, 127)
    #     Color.new([1, 2, 3]).with(:alpha => 0.4)
    #       #=> rgba(1, 2, 3, 0.4)
    #
    # @param attrs [{Symbol => Numeric}]
    #   A map of channel names (`:red`, `:green`, `:blue`,
    #   `:hue`, `:saturation`, `:lightness`, or `:alpha`) to values
    # @return [Color] The new Color object
    # @raise [ArgumentError] if both RGB and HSL keys are specified
    def with(attrs)
      attrs = attrs.reject {|_k, v| v.nil?}
      hsl = !([:hue, :saturation, :lightness] & attrs.keys).empty?
      rgb = !([:red, :green, :blue] & attrs.keys).empty?
      if hsl && rgb
        raise ArgumentError.new("Cannot specify HSL and RGB values for a color at the same time")
      end

      if hsl
        [:hue, :saturation, :lightness].each {|k| attrs[k] ||= send(k)}
      elsif rgb
        [:red, :green, :blue].each {|k| attrs[k] ||= send(k)}
      else
        # If we're just changing the alpha channel,
        # keep all the HSL/RGB stuff we've calculated
        attrs = @attrs.merge(attrs)
      end
      attrs[:alpha] ||= alpha

      Color.new(attrs, nil, :allow_both_rgb_and_hsl)
    end

    # The SassScript `+` operation.
    # Its functionality depends on the type of its argument:
    #
    # {Number}
    # : Adds the number to each of the RGB color channels.
    #
    # {Color}
    # : Adds each of the RGB color channels together.
    #
    # {Value}
    # : See {Value::Base#plus}.
    #
    # @param other [Value] The right-hand side of the operator
    # @return [Color] The resulting color
    # @raise [Sass::SyntaxError] if `other` is a number with units
    def plus(other)
      if other.is_a?(Sass::Script::Value::Number) || other.is_a?(Sass::Script::Value::Color)
        piecewise(other, :+)
      else
        super
      end
    end

    # The SassScript `-` operation.
    # Its functionality depends on the type of its argument:
    #
    # {Number}
    # : Subtracts the number from each of the RGB color channels.
    #
    # {Color}
    # : Subtracts each of the other color's RGB color channels from this color's.
    #
    # {Value}
    # : See {Value::Base#minus}.
    #
    # @param other [Value] The right-hand side of the operator
    # @return [Color] The resulting color
    # @raise [Sass::SyntaxError] if `other` is a number with units
    def minus(other)
      if other.is_a?(Sass::Script::Value::Number) || other.is_a?(Sass::Script::Value::Color)
        piecewise(other, :-)
      else
        super
      end
    end

    # The SassScript `*` operation.
    # Its functionality depends on the type of its argument:
    #
    # {Number}
    # : Multiplies the number by each of the RGB color channels.
    #
    # {Color}
    # : Multiplies each of the RGB color channels together.
    #
    # @param other [Number, Color] The right-hand side of the operator
    # @return [Color] The resulting color
    # @raise [Sass::SyntaxError] if `other` is a number with units
    def times(other)
      if other.is_a?(Sass::Script::Value::Number) || other.is_a?(Sass::Script::Value::Color)
        piecewise(other, :*)
      else
        raise NoMethodError.new(nil, :times)
      end
    end

    # The SassScript `/` operation.
    # Its functionality depends on the type of its argument:
    #
    # {Number}
    # : Divides each of the RGB color channels by the number.
    #
    # {Color}
    # : Divides each of this color's RGB color channels by the other color's.
    #
    # {Value}
    # : See {Value::Base#div}.
    #
    # @param other [Value] The right-hand side of the operator
    # @return [Color] The resulting color
    # @raise [Sass::SyntaxError] if `other` is a number with units
    def div(other)
      if other.is_a?(Sass::Script::Value::Number) ||
          other.is_a?(Sass::Script::Value::Color)
        piecewise(other, :/)
      else
        super
      end
    end

    # The SassScript `%` operation.
    # Its functionality depends on the type of its argument:
    #
    # {Number}
    # : Takes each of the RGB color channels module the number.
    #
    # {Color}
    # : Takes each of this color's RGB color channels modulo the other color's.
    #
    # @param other [Number, Color] The right-hand side of the operator
    # @return [Color] The resulting color
    # @raise [Sass::SyntaxError] if `other` is a number with units
    def mod(other)
      if other.is_a?(Sass::Script::Value::Number) ||
          other.is_a?(Sass::Script::Value::Color)
        piecewise(other, :%)
      else
        raise NoMethodError.new(nil, :mod)
      end
    end

    # Returns a string representation of the color.
    # This is usually the color's hex value,
    # but if the color has a name that's used instead.
    #
    # @return [String] The string representation
    def to_s(opts = {})
      return smallest if options[:style] == :compressed
      return representation if representation

      # IE10 doesn't properly support the color name "transparent", so we emit
      # generated transparent colors as rgba(0, 0, 0, 0) in favor of that. See
      # #1782.
      return rgba_str if Number.basically_equal?(alpha, 0)
      return name if name
      alpha? ? rgba_str : hex_str
    end
    alias_method :to_sass, :to_s

    # Returns a string representation of the color.
    #
    # @return [String] The hex value
    def inspect
      alpha? ? rgba_str : hex_str
    end

    # Returns the color's name, if it has one.
    #
    # @return [String, nil]
    def name
      COLOR_NAMES_REVERSE[rgba]
    end

    private

    def smallest
      small_explicit_str = alpha? ? rgba_str : hex_str.gsub(/^#(.)\1(.)\2(.)\3$/, '#\1\2\3')
      [representation, COLOR_NAMES_REVERSE[rgba], small_explicit_str].
          compact.min_by {|str| str.size}
    end

    def rgba_str
      split = options[:style] == :compressed ? ',' : ', '
      "rgba(#{rgb.join(split)}#{split}#{Number.round(alpha)})"
    end

    def hex_str
      red, green, blue = rgb.map {|num| num.to_s(16).rjust(2, '0')}
      "##{red}#{green}#{blue}"
    end

    def operation_name(operation)
      case operation
      when :+
        "add"
      when :-
        "subtract"
      when :*
        "multiply"
      when :/
        "divide"
      when :%
        "modulo"
      end
    end

    def piecewise(other, operation)
      other_num = other.is_a? Number
      if other_num && !other.unitless?
        raise Sass::SyntaxError.new(
          "Cannot #{operation_name(operation)} a number with units (#{other}) to a color (#{self})."
        )
      end

      result = []
      (0...3).each do |i|
        res = rgb[i].to_f.send(operation, other_num ? other.value : other.rgb[i])
        result[i] = [[res, 255].min, 0].max
      end

      if !other_num && other.alpha != alpha
        raise Sass::SyntaxError.new("Alpha channels must be equal: #{self} #{operation} #{other}")
      end

      with(:red => result[0], :green => result[1], :blue => result[2])
    end

    def hsl_to_rgb!
      return if @attrs[:red] && @attrs[:blue] && @attrs[:green]

      h = @attrs[:hue] / 360.0
      s = @attrs[:saturation] / 100.0
      l = @attrs[:lightness] / 100.0

      # Algorithm from the CSS3 spec: http://www.w3.org/TR/css3-color/#hsl-color.
      m2 = l <= 0.5 ? l * (s + 1) : l + s - l * s
      m1 = l * 2 - m2
      @attrs[:red], @attrs[:green], @attrs[:blue] = [
        hue_to_rgb(m1, m2, h + 1.0 / 3),
        hue_to_rgb(m1, m2, h),
        hue_to_rgb(m1, m2, h - 1.0 / 3)
      ].map {|c| Sass::Util.round(c * 0xff)}
    end

    def hue_to_rgb(m1, m2, h)
      h += 1 if h < 0
      h -= 1 if h > 1
      return m1 + (m2 - m1) * h * 6 if h * 6 < 1
      return m2 if h * 2 < 1
      return m1 + (m2 - m1) * (2.0 / 3 - h) * 6 if h * 3 < 2
      m1
    end

    def rgb_to_hsl!
      return if @attrs[:hue] && @attrs[:saturation] && @attrs[:lightness]
      r, g, b = [:red, :green, :blue].map {|k| @attrs[k] / 255.0}

      # Algorithm from http://en.wikipedia.org/wiki/HSL_and_HSV#Conversion_from_RGB_to_HSL_or_HSV
      max = [r, g, b].max
      min = [r, g, b].min
      d = max - min

      h =
        case max
        when min; 0
        when r; 60 * (g - b) / d
        when g; 60 * (b - r) / d + 120
        when b; 60 * (r - g) / d + 240
        end

      l = (max + min) / 2.0

      s =
        if max == min
          0
        elsif l < 0.5
          d / (2 * l)
        else
          d / (2 - 2 * l)
        end

      @attrs[:hue] = h % 360
      @attrs[:saturation] = s * 100
      @attrs[:lightness] = l * 100
    end
  end
end
