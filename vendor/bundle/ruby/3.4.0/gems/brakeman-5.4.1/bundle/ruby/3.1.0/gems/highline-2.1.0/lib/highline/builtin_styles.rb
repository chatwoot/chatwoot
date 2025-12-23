# coding: utf-8

class HighLine
  # Builtin Styles that are included at HighLine initialization.
  # It has the basic styles like :bold and :underline.
  module BuiltinStyles
    # Included callback
    # @param base [Class, Module] base class
    def self.included(base)
      base.extend ClassMethods
    end

    # Basic styles' ANSI escape codes like :bold => "\e[1m"
    STYLE_LIST = {
      erase_line: "\e[K",
      erase_char: "\e[P",
      clear:      "\e[0m",
      reset:      "\e[0m",
      bold:       "\e[1m",
      dark:       "\e[2m",
      underline:  "\e[4m",
      underscore: "\e[4m",
      blink:      "\e[5m",
      reverse:    "\e[7m",
      concealed:  "\e[8m"
    }.freeze

    STYLE_LIST.each do |style_name, code|
      style = String(style_name).upcase

      const_set style, code
      const_set style + "_STYLE",
                Style.new(name: style_name, code: code, builtin: true)
    end

    # Basic Style names like CLEAR, BOLD, UNDERLINE
    STYLES = %w[CLEAR RESET BOLD DARK UNDERLINE
                UNDERSCORE BLINK REVERSE CONCEALED].freeze

    # A Hash with the basic colors an their ANSI escape codes.
    COLOR_LIST = {
      black:   { code: "\e[30m", rgb: [0, 0, 0] },
      red:     { code: "\e[31m", rgb: [128, 0, 0] },
      green:   { code: "\e[32m", rgb: [0, 128, 0] },
      blue:    { code: "\e[34m", rgb: [0, 0, 128] },
      yellow:  { code: "\e[33m", rgb: [128, 128, 0] },
      magenta: { code: "\e[35m", rgb: [128, 0, 128] },
      cyan:    { code: "\e[36m", rgb: [0, 128, 128] },
      white:   { code: "\e[37m", rgb: [192, 192, 192] },
      gray:    { code: "\e[37m", rgb: [192, 192, 192] },
      grey:    { code: "\e[37m", rgb: [192, 192, 192] },
      none:    { code: "\e[38m", rgb: [0, 0, 0] }
    }.freeze

    COLOR_LIST.each do |color_name, attributes|
      color = String(color_name).upcase

      style = Style.new(
        name: color_name,
        code: attributes[:code],
        rgb:  attributes[:rgb],
        builtin: true
      )

      const_set color + "_STYLE", style
    end

    # The builtin styles basic colors like black, red, green.
    BASIC_COLORS =
      %w[BLACK RED GREEN YELLOW BLUE
         MAGENTA CYAN WHITE GRAY GREY NONE].freeze

    colors = BASIC_COLORS.dup
    BASIC_COLORS.each do |color|
      bright_color = "BRIGHT_#{color}"
      colors << bright_color
      const_set bright_color + "_STYLE", const_get(color + "_STYLE").bright

      light_color = "LIGHT_#{color}"
      colors << light_color
      const_set light_color + "_STYLE", const_get(color + "_STYLE").light
    end

    # The builtin styles' colors like LIGHT_RED and BRIGHT_BLUE.
    COLORS = colors

    colors.each do |color|
      const_set color, const_get("#{color}_STYLE").code
      const_set "ON_#{color}_STYLE", const_get("#{color}_STYLE").on
      const_set "ON_#{color}", const_get("ON_#{color}_STYLE").code
    end

    ON_NONE_STYLE.rgb = [255, 255, 255] # Override; white background

    # BuiltinStyles class methods to be extended.
    module ClassMethods
      # Regexp to match against RGB style constant names.
      RGB_COLOR_PATTERN = /^(ON_)?(RGB_)([A-F0-9]{6})(_STYLE)?$/

      # const_missing callback for automatically respond to
      # builtin constants (without explicitly defining them)
      # @param name [Symbol] missing constant name
      def const_missing(name)
        raise NameError, "Bad color or uninitialized constant #{name}" unless
          name.to_s =~ RGB_COLOR_PATTERN

        on = Regexp.last_match(1)
        suffix = Regexp.last_match(4)

        code_name = if suffix
                      Regexp.last_match(1).to_s +
                        Regexp.last_match(2) +
                        Regexp.last_match(3)
                    else
                      name.to_s
                    end

        style_name = code_name + "_STYLE"
        style = Style.rgb(Regexp.last_match(3))
        style = style.on if on

        const_set(style_name, style)
        const_set(code_name, style.code)

        suffix ? style : style.code
      end
    end
  end
end
