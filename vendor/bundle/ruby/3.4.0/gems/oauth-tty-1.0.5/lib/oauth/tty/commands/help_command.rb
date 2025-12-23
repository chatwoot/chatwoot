# frozen_string_literal: true

module OAuth
  module TTY
    module Commands
      class HelpCommand < Command
        def run
          puts <<-EOT
    Usage: oauth COMMAND [ARGS]

    Available oauth commands are:
      a, authorize  Obtain an access token and secret for a user
      q, query      Query a protected resource
      s, sign       Generate an OAuth signature

    In addition to those, there are:
      v, version    Displays the current version of the library (or --version, -v)
      h, help       Displays this help (or --help, -h)

    Tip: All commands can be run without args for specific help.


          EOT
        end
      end
    end
  end
end
