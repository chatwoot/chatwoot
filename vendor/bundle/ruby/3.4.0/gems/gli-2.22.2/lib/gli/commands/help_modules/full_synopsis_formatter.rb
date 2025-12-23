module GLI
  module Commands
    module HelpModules
      class FullSynopsisFormatter
        def initialize(app,flags_and_switches)
          @app = app
          @basic_invocation = @app.exe_name.to_s
          @flags_and_switches = flags_and_switches
        end

        def synopses_for_command(command)
          synopses = []
          one_line_usage = basic_usage(command)
          one_line_usage << ArgNameFormatter.new.format(command.arguments_description,command.arguments_options,command.arguments).strip
          if command.commands.empty?
            synopses << one_line_usage
          else
            synopses = sorted_synopses(command)
            if command.has_action?
              synopses.unshift(one_line_usage)
            end
          end
          synopses
        end

      protected

        def sub_options_doc(sub_options)
          sub_options_doc = sub_options.map { |_,option| 
            doc = option.names_and_aliases.map { |name|
              CommandLineOption.name_as_string(name,false) + (option.kind_of?(Flag) ? " #{option.argument_name }" : '')
            }.join('|')
            option.required?? doc : "[#{doc}]"
          }.sort.join(' ').strip
        end

      private

        def path_to_command(command)
          path = []
          c = command
          while c.kind_of? Command
            path.unshift(c.name)
            c = c.parent
          end
          path.join(' ')
        end
 

        def basic_usage(command)
          usage = @basic_invocation.dup
          usage << " [global options]" unless global_flags_and_switches.empty?
          usage << " #{path_to_command(command)}"
          usage << " [command options]" unless @flags_and_switches.empty?
          usage << " "
          usage
        end

 
        def command_with_subcommand_usage(command,sub,is_default_command)
          usage = basic_usage(command)
          sub_options = if @app.subcommand_option_handling_strategy == :legacy 
                          command.flags.merge(command.switches).select { |_,o| o.associated_command == sub }
                        else
                          sub.flags.merge(sub.switches)
                        end
          if is_default_command
            usage << "[#{sub.name}]"
          else
            usage << sub.name.to_s
          end
          sub_options_doc = sub_options_doc(sub_options)
          if sub_options_doc.length > 0
            usage << ' '
            usage << sub_options_doc
          end
          arg_name_doc = ArgNameFormatter.new.format(sub.arguments_description,sub.arguments_options,sub.arguments).strip
          if arg_name_doc.length > 0
            usage << ' '
            usage << arg_name_doc
          end
          usage
        end

        def sorted_synopses(command)
          synopses_command = {}
          command.commands.each do |name,sub|
            default = command.get_default_command == name
            synopsis = command_with_subcommand_usage(command,sub,default)
            synopses_command[synopsis] = sub
          end
          synopses = synopses_command.keys.sort { |one,two|
            if synopses_command[one].name == command.get_default_command
              -1
            elsif synopses_command[two].name == command.get_default_command
              1
            else
              synopses_command[one] <=> synopses_command[two]
            end
          }
        end

        def global_flags_and_switches
          @app.flags.merge(@app.switches)
        end
 
      end
    end
  end
end
