# frozen_string_literal: true

module Datadog
  module Profiling
    module Tasks
      # Prints help message for usage of `ddprofrb`
      class Help
        def run
          puts %(
  Usage: ddprofrb [command] [arguments]
    exec [command]: Executes command with profiling preloaded.
    help:           Prints this help message.
          )
        end
      end
    end
  end
end
