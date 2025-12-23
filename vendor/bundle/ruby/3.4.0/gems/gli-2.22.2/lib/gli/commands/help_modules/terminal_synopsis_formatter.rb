module GLI
  module Commands
    module HelpModules
      class TerminalSynopsisFormatter
        def initialize(app,flags_and_switches)
          @app = app
          @basic_invocation = @app.exe_name.to_s
          @flags_and_switches = flags_and_switches
        end
        def synopses_for_command(command)
          synopses = FullSynopsisFormatter.new(@app,@flags_and_switches).synopses_for_command(command)
          if synopses.any? { |synopsis| synopsis.length > Terminal.instance.size[0] }
            CompactSynopsisFormatter.new(@app,@flags_and_switches).synopses_for_command(command)

          else
            synopses
          end
        end
      end
    end
  end
end
