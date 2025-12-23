require 'erb'

module GLI
  module Commands
    module HelpModules
      class CommandHelpFormat
        def initialize(command,app,sorter,synopsis_formatter_class,wrapper_class=TextWrapper)
          @app = app
          @command = command
          @sorter = sorter
          @wrapper_class = wrapper_class
          @synopsis_formatter = synopsis_formatter_class.new(@app,flags_and_switches(@command,@app))
        end

        def format
          command_wrapper      = @wrapper_class.new(Terminal.instance.size[0],4 + @command.name.to_s.size + 3)
          wrapper              = @wrapper_class.new(Terminal.instance.size[0],4)
          
          options_description  = OptionsFormatter.new(flags_and_switches(@command,@app),@sorter,@wrapper_class).format
          commands_description = format_subcommands(@command)
          command_examples = format_examples(@command)

          synopses = @synopsis_formatter.synopses_for_command(@command)
          COMMAND_HELP.result(binding)
        end

      private
        COMMAND_HELP = ERB.new(%q(NAME
    <%= @command.name %> - <%= command_wrapper.wrap(@command.description) %>

SYNOPSIS
<% synopses.each do |s| %>
    <%= s %>
<% end %><% unless @command.long_description.nil? %>

DESCRIPTION
    <%= wrapper.wrap(@command.long_description) %> 
<% end %><% if options_description.strip.length != 0 %>
COMMAND OPTIONS
<%= options_description %>
<% end %><% unless @command.commands.empty? %>
COMMANDS
<%= commands_description %>
<% end %><% unless @command.examples.empty? %>
<%= @command.examples.size == 1 ? 'EXAMPLE' : 'EXAMPLES' %>

<%= command_examples %>
<% end %>))


        def flags_and_switches(command,app)
          if app.subcommand_option_handling_strategy == :legacy
            (
              command.topmost_ancestor.flags_declaration_order + 
              command.topmost_ancestor.switches_declaration_order
            ).select { |option| option.associated_command == command }
          else
            (
              command.flags_declaration_order + 
              command.switches_declaration_order
            )
          end
        end
 
        def format_subcommands(command)
          commands_array = @sorter.call(command.commands_declaration_order).map { |cmd| 
            if command.get_default_command == cmd.name
              [cmd.names,String(cmd.description) + " (default)"] 
            else
              [cmd.names,cmd.description] 
            end
          }
          if command.has_action?
            commands_array.unshift(["<default>",command.default_description])
          end
          formatter = ListFormatter.new(commands_array,@wrapper_class)
          StringIO.new.tap { |io| formatter.output(io) }.string
        end

        def format_examples(command)
          command.examples.map {|example|
            string = ""
            if example[:desc]
              string << "    # #{example[:desc]}\n"
            end
            string << "    #{example.fetch(:example)}\n"
          }.join("\n")
        end
      end
    end
  end
end
