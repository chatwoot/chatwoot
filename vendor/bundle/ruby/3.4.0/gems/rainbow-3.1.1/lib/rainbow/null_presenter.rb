# frozen_string_literal: true

module Rainbow
  class NullPresenter < ::String
    def color(*_values)
      self
    end

    def background(*_values)
      self
    end

    def reset
      self
    end

    def bright
      self
    end

    def faint
      self
    end

    def italic
      self
    end

    def underline
      self
    end

    def blink
      self
    end

    def inverse
      self
    end

    def hide
      self
    end

    def cross_out
      self
    end

    def black
      self
    end

    def red
      self
    end

    def green
      self
    end

    def yellow
      self
    end

    def blue
      self
    end

    def magenta
      self
    end

    def cyan
      self
    end

    def white
      self
    end

    def method_missing(method_name, *args)
      if Color::X11Named.color_names.include?(method_name) && args.empty?
        self
      else
        super
      end
    end

    def respond_to_missing?(method_name, *args)
      Color::X11Named.color_names.include?(method_name) && args.empty? || super
    end

    alias foreground color
    alias fg color
    alias bg background
    alias bold bright
    alias dark faint
    alias strike cross_out
  end
end
