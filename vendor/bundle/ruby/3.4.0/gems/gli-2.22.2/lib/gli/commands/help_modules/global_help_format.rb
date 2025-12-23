require 'erb'

module GLI
  module Commands
    module HelpModules
      class GlobalHelpFormat
        def initialize(app,sorter,wrapper_class)
          @app = app
          @sorter = sorter
          @wrapper_class = wrapper_class
        end

        def format
          program_desc = @app.program_desc
          program_long_desc = @app.program_long_desc
          if program_long_desc
            wrapper = @wrapper_class.new(Terminal.instance.size[0],4)
            program_long_desc = "\n    #{wrapper.wrap(program_long_desc)}\n\n" if program_long_desc
          else
            program_long_desc = "\n"
          end

          command_formatter = ListFormatter.new(@sorter.call(@app.commands_declaration_order.reject(&:nodoc)).map { |command|
            [[command.name,Array(command.aliases)].flatten.join(', '),command.description]
          }, @wrapper_class)
          stringio = StringIO.new
          command_formatter.output(stringio)
          commands = stringio.string

          global_option_descriptions = OptionsFormatter.new(global_flags_and_switches,@sorter,@wrapper_class).format

          GLOBAL_HELP.result(binding)
        end

      private

        GLOBAL_HELP = ERB.new(%q(NAME
    <%= @app.exe_name %> - <%= program_desc %>
<%= program_long_desc %>
SYNOPSIS
    <%= usage_string %>

<% unless @app.version_string.nil? %>
VERSION
    <%= @app.version_string %>

<% end %><% unless global_flags_and_switches.empty? %>
GLOBAL OPTIONS
<%= global_option_descriptions %>
<% end %>
COMMANDS
<%= commands %>))

        def global_flags_and_switches
          @app.flags_declaration_order + @app.switches_declaration_order
        end

        def usage_string
          "#{@app.exe_name} ".tap do |string|
            string << "[global options] " unless global_flags_and_switches.empty?
            string << "command "
            string << "[command options] [arguments...]"
          end
        end
      end
    end
  end
end
