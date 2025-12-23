# frozen_string_literal: true

class Pry
  class Command
    class FixIndent < Pry::ClassCommand
      match 'fix-indent'
      group 'Input and Output'

      description "Correct the indentation for contents of the input buffer"

      banner <<-USAGE
        Usage: fix-indent
      USAGE

      def process
        indented_str = Pry::Indent.indent(eval_string)
        pry_instance.eval_string = indented_str
      end
    end

    Pry::Commands.add_command(Pry::Command::FixIndent)
  end
end
