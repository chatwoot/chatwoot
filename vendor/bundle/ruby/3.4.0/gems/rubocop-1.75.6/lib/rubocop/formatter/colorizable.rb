# frozen_string_literal: true

module RuboCop
  module Formatter
    # This mix-in module provides string coloring methods for terminals.
    # It automatically disables coloring if coloring is disabled in the process
    # globally or the formatter's output is not a terminal.
    module Colorizable
      def rainbow
        @rainbow ||= begin
          rainbow = Rainbow.new
          if options[:color]
            rainbow.enabled = true
          elsif options[:color] == false || !output.tty?
            rainbow.enabled = false
          end
          rainbow
        end
      end

      def colorize(string, *args)
        rainbow.wrap(string).color(*args)
      end

      %i[
        black
        red
        green
        yellow
        blue
        magenta
        cyan
        white
      ].each do |color|
        define_method(color) do |string|
          colorize(string, color)
        end
      end
    end
  end
end
