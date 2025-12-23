# frozen_string_literal: true

module RuboCop
  class CLI
    # Home of subcommands in the CLI.
    # @api private
    module Command
      class << self
        # Find the command with a given name and run it in an environment.
        def run(env, name)
          class_for(name).new(env).run
        end

        private

        def class_for(name)
          Base.by_command_name(name)
        end
      end
    end
  end
end
