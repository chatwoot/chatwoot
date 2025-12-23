# frozen_string_literal: true

require_relative "command_processor"

module Byebug
  #
  # Processes commands from a file
  #
  class ScriptProcessor < CommandProcessor
    #
    # Available commands
    #
    def commands
      super.select(&:allow_in_control)
    end

    def repl
      while (input = interface.read_command(prompt))
        safely do
          command = command_list.match(input)
          raise CommandNotFound.new(input) unless command

          command.new(self, input).execute
        end
      end
    end

    def after_repl
      super

      interface.close
    end

    #
    # Prompt shown before reading a command.
    #
    def prompt
      "(byebug:ctrl) "
    end

    private

    def without_exceptions
      yield
    rescue StandardError
      nil
    end
  end
end
