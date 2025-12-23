# frozen_string_literal: true

module RuboCop
  class CLI
    module Command
      # A subcommand in the CLI.
      # @api private
      class Base
        attr_reader :env

        @subclasses = []

        class << self
          attr_accessor :command_name

          def inherited(subclass)
            super
            @subclasses << subclass
          end

          def by_command_name(name)
            @subclasses.detect { |s| s.command_name == name }
          end
        end

        def initialize(env)
          @env = env
          @options = env.options
          @config_store = env.config_store
          @paths = env.paths
        end
      end
    end
  end
end
