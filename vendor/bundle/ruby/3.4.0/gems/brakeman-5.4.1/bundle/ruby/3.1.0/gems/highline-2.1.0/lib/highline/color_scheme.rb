# coding: utf-8

#--
# color_scheme.rb
#
# Created by Jeremy Hinegardner on 2007-01-24
# Copyright 2007.  All rights reserved
#
# This is Free Software.  See LICENSE and COPYING for details

class HighLine
  #
  # ColorScheme objects encapsulate a named set of colors to be used in the
  # {HighLine.color} method call.  For example, by applying a ColorScheme that
  # has a <tt>:warning</tt> color then the following could be used:
  #
  #   color("This is a warning", :warning)
  #
  # A ColorScheme contains named sets of HighLine color constants.
  #
  # @example Instantiating a color scheme, applying it to HighLine,
  #   and using it:
  #   ft = HighLine::ColorScheme.new do |cs|
  #          cs[:headline]        = [ :bold, :yellow, :on_black ]
  #          cs[:horizontal_line] = [ :bold, :white ]
  #          cs[:even_row]        = [ :green ]
  #          cs[:odd_row]         = [ :magenta ]
  #        end
  #
  #   HighLine.color_scheme = ft
  #   say("<%= color('Headline', :headline) %>")
  #   say("<%= color('-'*20, :horizontal_line) %>")
  #   i = true
  #   ("A".."D").each do |row|
  #      if i then
  #        say("<%= color('#{row}', :even_row ) %>")
  #      else
  #        say("<%= color('#{row}', :odd_row) %>")
  #      end
  #      i = !i
  #   end
  #
  #
  class ColorScheme
    #
    # Create an instance of HighLine::ColorScheme. The customization can
    # happen as a passed in Hash or via the yielded block.  Keys are
    # converted to <tt>:symbols</tt> and values are converted to HighLine
    # constants.
    #
    # @param h [Hash]
    def initialize(h = nil)
      @scheme = {}
      load_from_hash(h) if h
      yield self if block_given?
    end

    # Load multiple colors from key/value pairs.
    # @param h [Hash]
    def load_from_hash(h)
      h.each_pair do |color_tag, constants|
        self[color_tag] = constants
      end
    end

    # Does this color scheme include the given tag name?
    # @param color_tag [#to_sym]
    # @return [Boolean]
    def include?(color_tag)
      @scheme.keys.include?(to_symbol(color_tag))
    end

    # Allow the scheme to be accessed like a Hash.
    # @param color_tag [#to_sym]
    # @return [Style]
    def [](color_tag)
      @scheme[to_symbol(color_tag)]
    end

    # Retrieve the original form of the scheme
    # @param color_tag [#to_sym]
    def definition(color_tag)
      style = @scheme[to_symbol(color_tag)]
      style && style.list
    end

    # Retrieve the keys in the scheme
    # @return [Array] of keys
    def keys
      @scheme.keys
    end

    # Allow the scheme to be set like a Hash.
    # @param color_tag [#to_sym]
    # @param constants [Array<Symbol>] Array of Style symbols
    def []=(color_tag, constants)
      @scheme[to_symbol(color_tag)] =
        HighLine::Style.new(name: color_tag.to_s.downcase.to_sym,
                            list: constants,
                            no_index: true)
    end

    # Retrieve the color scheme hash (in original definition format)
    # @return [Hash] scheme as Hash. It may be reused in a new ColorScheme.
    def to_hash
      @scheme.each_with_object({}) do |pair, hsh|
        key, value = pair
        hsh[key] = value.list
      end
    end

    private

    # Return a normalized representation of a color name.
    def to_symbol(t)
      t.to_s.downcase
    end

    # Return a normalized representation of a color setting.
    def to_constant(v)
      v = v.to_s if v.is_a?(Symbol)
      if v.is_a?(::String)
        HighLine.const_get(v.upcase)
      else
        v
      end
    end
  end

  # A sample ColorScheme.
  class SampleColorScheme < ColorScheme
    SAMPLE_SCHEME = {
      critical: [:yellow, :on_red],
      error: [:bold, :red],
      warning: [:bold, :yellow],
      notice: [:bold, :magenta],
      info: [:bold, :cyan],
      debug: [:bold, :green],
      row_even: [:cyan],
      row_odd: [:magenta]
    }.freeze
    #
    # Builds the sample scheme with settings for <tt>:critical</tt>,
    # <tt>:error</tt>, <tt>:warning</tt>, <tt>:notice</tt>, <tt>:info</tt>,
    # <tt>:debug</tt>, <tt>:row_even</tt>, and <tt>:row_odd</tt> colors.
    #
    def initialize(_h = nil)
      super(SAMPLE_SCHEME)
    end
  end
end
