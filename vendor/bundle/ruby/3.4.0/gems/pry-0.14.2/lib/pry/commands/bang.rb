# frozen_string_literal: true

class Pry
  class Command
    class Bang < Pry::ClassCommand
      match(/^\s*!\s*$/)
      group 'Editing'
      description 'Clear the input buffer.'
      command_options use_prefix: false, listing: '!'

      banner <<-'BANNER'
        Clear the input buffer. Useful if the parsing process goes wrong and you get
        stuck in the read loop.
      BANNER

      def process
        output.puts 'Input buffer cleared!'
        eval_string.replace('')
      end
    end

    Pry::Commands.add_command(Pry::Command::Bang)
  end
end
