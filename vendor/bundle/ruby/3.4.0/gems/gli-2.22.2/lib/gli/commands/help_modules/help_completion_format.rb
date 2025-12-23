module GLI
  module Commands
    module HelpModules
      class HelpCompletionFormat
        def initialize(app,command_finder,args)
          @app = app
          @command_finder = command_finder
          @command_finder.squelch_stderr = true
          @args = args
        end

        def format
          name = @args.shift

          base = @command_finder.find_command(name)
          base = @command_finder.last_found_command if base.nil?
          base = @app if base.nil?

          prefix_to_match = @command_finder.last_unknown_command

          base.commands.values.map { |command|
            [command.name,command.aliases]
          }.flatten.compact.map(&:to_s).sort.select { |command_name|
            prefix_to_match.nil? || command_name =~ /^#{prefix_to_match}/
          }.join("\n")
        end

      end
    end
  end
end
