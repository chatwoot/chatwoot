# coding: utf-8

#--
# originally color_scheme.rb
#
# Created by Richard LeBer on 2011-06-27.
# Copyright 2011.  All rights reserved
#
# This is Free Software.  See LICENSE and COPYING for details

class HighLine #:nodoc:
  # Creates a style using {.find_or_create_style} or
  # {.find_or_create_style_list}
  # @param args [Array<Style, Hash, String>] style properties
  # @return [Style]
  def self.Style(*args)
    args = args.compact.flatten
    if args.size == 1
      find_or_create_style(args.first)
    else
      find_or_create_style_list(*args)
    end
  end

  # Search for a Style with the given properties and return it.
  # If there's no matched Style, it creates one.
  # You can pass a Style, String or a Hash.
  # @param arg [Style, String, Hash] style properties
  # @return [Style] found or creted Style
  def self.find_or_create_style(arg)
    if arg.is_a?(Style)
      Style.list[arg.name] || Style.index(arg)
    elsif arg.is_a?(::String) && arg =~ /^\e\[/ # arg is a code
      styles = Style.code_index[arg]
      if styles
        styles.first
      else
        Style.new(code: arg)
      end
    elsif Style.list[arg]
      Style.list[arg]
    elsif HighLine.color_scheme && HighLine.color_scheme[arg]
      HighLine.color_scheme[arg]
    elsif arg.is_a?(Hash)
      Style.new(arg)
    elsif arg.to_s.downcase =~ /^rgb_([a-f0-9]{6})$/
      Style.rgb(Regexp.last_match(1))
    elsif arg.to_s.downcase =~ /^on_rgb_([a-f0-9]{6})$/
      Style.rgb(Regexp.last_match(1)).on
    else
      raise NameError, "#{arg.inspect} is not a defined Style"
    end
  end

  # Find a Style list or create a new one.
  # @param args [Array<Symbol>] an Array of Symbols of each style
  #   that will be on the style list.
  # @return [Style] Style list
  # @example Creating a Style list of the combined RED and BOLD styles.
  #   style_list = HighLine.find_or_create_style_list(:red, :bold)

  def self.find_or_create_style_list(*args)
    name = args
    Style.list[name] || Style.new(list: args)
  end

  # ANSI styles to be used by HighLine.
  class Style
    # Index the given style.
    # Uses @code_index (Hash) as repository.
    # @param style [Style]
    # @return [Style] the given style
    def self.index(style)
      if style.name
        @styles ||= {}
        @styles[style.name] = style
      end
      unless style.list
        @code_index ||= {}
        @code_index[style.code] ||= []
        @code_index[style.code].reject! do |indexed_style|
          indexed_style.name == style.name
        end
        @code_index[style.code] << style
      end
      style
    end

    # Clear all custom Styles, restoring the Style index to
    # builtin styles only.
    # @return [void]
    def self.clear_index
      # reset to builtin only styles
      @styles = list.select { |_name, style| style.builtin }
      @code_index = {}
      @styles.each_value { |style| index(style) }
    end

    # Converts all given color codes to hexadecimal and
    # join them in a single string. If any given color code
    # is already a String, doesn't perform any convertion.
    #
    # @param colors [Array<Numeric, String>] color codes
    # @return [String] all color codes joined
    # @example
    #   HighLine::Style.rgb_hex(9, 10, "11") # => "090a11"
    def self.rgb_hex(*colors)
      colors.map do |color|
        color.is_a?(Numeric) ? format("%02x", color) : color.to_s
      end.join
    end

    # Split an rgb code string into its 3 numerical compounds.
    # @param hex [String] rgb code string like "010F0F"
    # @return [Array<Numeric>] numerical compounds like [1, 15, 15]
    # @example
    #   HighLine::Style.rgb_parts("090A0B") # => [9, 10, 11]

    def self.rgb_parts(hex)
      hex.scan(/../).map { |part| part.to_i(16) }
    end

    # Search for or create a new Style from the colors provided.
    # @param colors (see .rgb_hex)
    # @return [Style] a Style with the rgb colors provided.
    # @example Creating a new Style based on rgb code
    #   rgb_style = HighLine::Style.rgb(9, 10, 11)
    #
    #   rgb_style.name #  => :rgb_090a0b
    #   rgb_style.code #  => "\e[38;5;16m"
    #   rgb_style.rgb  #  => [9, 10, 11]
    #
    def self.rgb(*colors)
      hex = rgb_hex(*colors)
      name = ("rgb_" + hex).to_sym
      style = list[name]
      return style if style

      parts = rgb_parts(hex)
      new(name: name, code: "\e[38;5;#{rgb_number(parts)}m", rgb: parts)
    end

    # Returns the rgb number to be used as escape code on ANSI terminals.
    # @param parts [Array<Numeric>] three numerical codes for red, green
    #   and blue
    # @return [Numeric] to be used as escape code on ANSI terminals
    def self.rgb_number(*parts)
      parts = parts.flatten
      16 + parts.reduce(0) do |kode, part|
        kode * 6 + (part / 256.0 * 6.0).floor
      end
    end

    # From an ANSI number (color escape code), craft an 'rgb_hex' code of it
    # @param ansi_number [Integer] ANSI escape code
    # @return [String] all color codes joined as {.rgb_hex}
    def self.ansi_rgb_to_hex(ansi_number)
      raise "Invalid ANSI rgb code #{ansi_number}" unless
        (16..231).cover?(ansi_number)
      parts = (ansi_number - 16).
              to_s(6).
              rjust(3, "0").
              scan(/./).
              map { |d| (d.to_i * 255.0 / 6.0).ceil }

      rgb_hex(*parts)
    end

    # @return [Hash] list of all cached Styles
    def self.list
      @styles ||= {}
    end

    # @return [Hash] list of all cached Style codes
    def self.code_index
      @code_index ||= {}
    end

    # Remove any ANSI color escape sequence of the given String.
    # @param string [String]
    # @return [String]
    def self.uncolor(string)
      string.gsub(/\e\[\d+(;\d+)*m/, "")
    end

    # Style name
    # @return [Symbol] the name of the Style
    attr_reader :name

    # When a compound Style, returns a list of its components.
    # @return [Array<Symbol>] components of a Style list
    attr_reader :list

    # @return [Array] the three numerical rgb codes. Ex: [10, 12, 127]
    attr_accessor :rgb

    # @return [Boolean] true if the Style is builtin or not.
    attr_accessor :builtin

    # Single color/styles have :name, :code, :rgb (possibly), :builtin
    # Compound styles have :name, :list, :builtin
    #
    # @param defn [Hash] options for the Style to be created.
    def initialize(defn = {})
      @definition = defn
      @name    = defn[:name]
      @code    = defn[:code]
      @rgb     = defn[:rgb]
      @list    = defn[:list]
      @builtin = defn[:builtin]
      if @rgb
        hex = self.class.rgb_hex(@rgb)
        @name ||= "rgb_" + hex
      elsif @list
        @name ||= @list
      end
      self.class.index self unless defn[:no_index]
    end

    # Duplicate current Style using the same definition used to create it.
    # @return [Style] duplicated Style
    def dup
      self.class.new(@definition)
    end

    # @return [Hash] the definition used to create this Style
    def to_hash
      @definition
    end

    # Uses the Style definition to add ANSI color escape codes
    # to a a given String
    # @param string [String] to be colored
    # @return [String] an ANSI colored string
    def color(string)
      code + string + HighLine::CLEAR
    end

    # @return [String] all codes of the Style list joined together
    #   (if a Style list)
    # @return [String] the Style code
    def code
      if @list
        @list.map { |element| HighLine.Style(element).code }.join
      else
        @code
      end
    end

    # @return [Integer] the RED component of the rgb code
    def red
      @rgb && @rgb[0]
    end

    # @return [Integer] the GREEN component of the rgb code
    def green
      @rgb && @rgb[1]
    end

    # @return [Integer] the BLUE component of the rgb code
    def blue
      @rgb && @rgb[2]
    end

    # Duplicate Style with some minor changes
    # @param new_name [Symbol]
    # @param options [Hash] Style attributes to be changed
    # @return [Style] new Style with changed attributes
    def variant(new_name, options = {})
      raise "Cannot create a variant of a style list (#{inspect})" if @list
      new_code = options[:code] || code
      if options[:increment]
        raise "Unexpected code in #{inspect}" unless
          new_code =~ /^(.*?)(\d+)(.*)/

        new_code =
          Regexp.last_match(1) +
          (Regexp.last_match(2).to_i +
          options[:increment]).to_s +
          Regexp.last_match(3)
      end
      new_rgb = options[:rgb] || @rgb
      self.class.new(to_hash.merge(name: new_name,
                                   code: new_code,
                                   rgb: new_rgb))
    end

    # Uses the color as background and return a new style.
    # @return [Style]
    def on
      new_name = ("on_" + @name.to_s).to_sym
      self.class.list[new_name] ||= variant(new_name, increment: 10)
    end

    # @return [Style] a brighter version of this Style
    def bright
      create_bright_variant(:bright)
    end

    # @return [Style] a lighter version of this Style
    def light
      create_bright_variant(:light)
    end

    private

    def create_bright_variant(variant_name)
      raise "Cannot create a #{name} variant of a style list (#{inspect})" if
        @list
      new_name = ("#{variant_name}_" + @name.to_s).to_sym
      new_rgb =
        if @rgb == [0, 0, 0]
          [128, 128, 128]
        else
          @rgb.map { |color| color.zero? ? 0 : [color + 128, 255].min }
        end

      find_style(new_name) || variant(new_name, increment: 60, rgb: new_rgb)
    end

    def find_style(name)
      self.class.list[name]
    end
  end
end
