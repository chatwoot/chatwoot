# frozen_string_literal: true

module RuboCop
  class CLI
    # Execution environment for a CLI command.
    # @api private
    class Environment
      attr_reader :options, :config_store, :paths

      def initialize(options, config_store, paths)
        @options = options
        @config_store = config_store
        @paths = paths
      end

      # Run a command in this environment.
      def run(name)
        Command.run(self, name)
      end
    end
  end
end
