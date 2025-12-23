# frozen_string_literal: true

class Pry
  class Command
    class ImportSet < Pry::ClassCommand
      match 'import-set'
      group 'Commands'
      # TODO: Provide a better description with examples and a general conception
      # of this command.
      description 'Import a Pry command set.'

      banner <<-'BANNER'
        Import a Pry command set.
      BANNER

      # TODO: resolve unused parameter.
      def process(_command_set_name)
        raise CommandError, "Provide a command set name" if command_set.nil?

        set = target.eval(arg_string)
        pry_instance.commands.import set
      end
    end

    Pry::Commands.add_command(Pry::Command::ImportSet)
  end
end
