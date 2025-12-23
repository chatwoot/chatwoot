module GLI
  module Commands
    module HelpModules
      # Finds commands from the application/command data structures
      class CommandFinder

        attr_reader :last_unknown_command
        attr_reader :last_found_command
        attr_writer :squelch_stderr

        def initialize(app,arguments,error)
          @app = app
          @arguments = arguments
          @error = error
          @squelch_stderr = false
          @last_unknown_command = nil
        end

        def find_command(name)
          command = find_command_from_base(name,@app)
          return if unknown_command?(command,name,@error)
          @last_found_command = command
          while !@arguments.empty?
            name = @arguments.shift
            command = find_command_from_base(name,command)
            return if unknown_command?(command,name,@error)
            @last_found_command = command
          end
          command
        end

      private

        # Given the name of a command to find, and a base, either the app or another command, returns
        # the command object or nil.
        def find_command_from_base(command_name,base)
          base.commands.values.select { |command|
            if [command.name,Array(command.aliases)].flatten.map(&:to_s).any? { |_| _ == command_name }
              command
            end
          }.first
        end

        # Checks if the return from find_command was unknown and, if so, prints an error
        # for the user on the error device, returning true or false if the command was unknown.
        def unknown_command?(command,name,error)
          if command.nil?
            @last_unknown_command = name
            unless @squelch_stderr
              error.puts "error: Unknown command '#{name}'.  Use '#{@app.exe_name} help' for a list of commands."
            end
            true
          else
            false
          end
        end
      end
    end
  end
end
