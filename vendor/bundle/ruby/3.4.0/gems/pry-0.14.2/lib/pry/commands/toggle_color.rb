# frozen_string_literal: true

class Pry
  class Command
    class ToggleColor < Pry::ClassCommand
      match 'toggle-color'
      group 'Misc'
      description 'Toggle syntax highlighting.'

      banner <<-'BANNER'
        Usage: toggle-color

        Toggle syntax highlighting.
      BANNER

      def process
        pry_instance.color = color_toggle
        output.puts "Syntax highlighting #{pry_instance.color ? 'on' : 'off'}"
      end

      def color_toggle
        !pry_instance.color
      end

      Pry::Commands.add_command(self)
    end
  end
end
