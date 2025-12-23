# frozen_string_literal: true

class Pry
  class Command
    class ChangeInspector < Pry::ClassCommand
      match 'change-inspector'
      group 'Input and Output'
      description 'Change the current inspector proc.'
      command_options argument_required: true
      banner <<-BANNER
        Usage: change-inspector NAME

        Change the proc used to print return values. See list-inspectors for a list
        of available procs and a short description of what each one does.
      BANNER

      def process(inspector)
        unless inspector_map.key?(inspector)
          raise Pry::CommandError, "'#{inspector}' isn't a known inspector!"
        end

        pry_instance.print = inspector_map[inspector][:value]
        output.puts "Switched to the '#{inspector}' inspector!"
      end

      private

      def inspector_map
        Pry::Inspector::MAP
      end
      Pry::Commands.add_command(self)
    end
  end
end
