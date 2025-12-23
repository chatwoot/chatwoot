# frozen_string_literal: true

class Pry
  class Command
    class Reset < Pry::ClassCommand
      match 'reset'
      group 'Context'
      description 'Reset the REPL to a clean state.'

      banner <<-'BANNER'
        Reset the REPL to a clean state.
      BANNER

      def process
        output.puts 'Pry reset.'
        exec 'pry'
      end
    end

    Pry::Commands.add_command(Pry::Command::Reset)
  end
end
