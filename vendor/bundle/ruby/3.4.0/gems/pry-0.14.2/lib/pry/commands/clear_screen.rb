# frozen_string_literal: true

class Pry
  class Command
    class ClearScreen < Pry::ClassCommand
      match 'clear-screen'
      group 'Input and Output'
      description 'Clear the contents of the screen/window Pry is running in.'

      def process
        if Pry::Helpers::Platform.windows?
          pry_instance.config.system.call(pry_instance.output, 'cls', pry_instance)
        else
          pry_instance.config.system.call(pry_instance.output, 'clear', pry_instance)
        end
      end
      Pry::Commands.add_command(self)
    end
  end
end
