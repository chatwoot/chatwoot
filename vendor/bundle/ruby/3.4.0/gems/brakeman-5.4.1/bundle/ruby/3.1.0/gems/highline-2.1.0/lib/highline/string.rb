# coding: utf-8

require "highline/string_extensions"

class HighLine
  #
  # HighLine::String is a subclass of String with convenience methods added
  # for colorization.
  #
  # Available convenience methods include:
  #   * 'color' method         e.g.  highline_string.color(:bright_blue,
  #                                                        :underline)
  #   * colors                 e.g.  highline_string.magenta
  #   * RGB colors             e.g.  highline_string.rgb_ff6000
  #                             or   highline_string.rgb(255,96,0)
  #   * background colors      e.g.  highline_string.on_magenta
  #   * RGB background colors  e.g.  highline_string.on_rgb_ff6000
  #                             or   highline_string.on_rgb(255,96,0)
  #   * styles                 e.g.  highline_string.underline
  #
  # Additionally, convenience methods can be chained, for instance the
  # following are equivalent:
  #   highline_string.bright_blue.blink.underline
  #   highline_string.color(:bright_blue, :blink, :underline)
  #   HighLine.color(highline_string, :bright_blue, :blink, :underline)
  #
  # For those less squeamish about possible conflicts, the same convenience
  # methods can be added to the built-in String class, as follows:
  #
  #  require 'highline'
  #  Highline.colorize_strings
  #
  class String < ::String
    include StringExtensions
  end
end
