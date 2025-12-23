require 'rake/tasklib'

module Bundler
  module Audit
    #
    # Defines the `bundle:audit` rake tasks.
    #
    class Task < Rake::TaskLib
      class CommandNotFound < RuntimeError
      end

      #
      # Initializes the task.
      #
      def initialize
        define
      end

      protected

      #
      # Defines the `bundle:audit` and `bundle:audit:update` task.
      #
      def define
        namespace :bundle do
          namespace :audit do
            desc 'Checks the Gemfile.lock for insecure dependencies'
            task :check do
              bundler_audit 'check'
            end

            desc 'Updates the bundler-audit vulnerability database'
            task :update do
              bundler_audit 'update'
            end
          end

          task :audit => 'audit:check'
        end

        task 'bundler:audit'        => 'bundle:audit'
        task 'bundler:audit:check'  => 'bundle:audit:check'
        task 'bundler:audit:update' => 'bundle:audit:update'
      end

      #
      # Runs the `bundler-audit` command with the additional arguments.
      #
      # @param [Array<String>] arguments
      #   Additional command-line arguments for `bundler-audit`.
      #
      # @return [true]
      #   The `bundler-audit` command successfully exited.
      #
      # @raise [CommandNotFound]
      #   The `bundler-audit` command could not be executed or was not found.
      #
      # @note
      #   If the `bundler-audit` command exits with an error, the rake task
      #   will also exit with the same error code.
      #
      def bundler_audit(*arguments)
        case system('bundler-audit',*arguments)
        when false
          exit $?.exitstatus || 1
        when nil
          raise(CommandNotFound,"bundler-audit could not be executed")
        else
          return true
        end
      end
    end
  end
end
