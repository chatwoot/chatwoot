# frozen_string_literal: true

module RuboCop
  # This is a class that reads optional command line arguments to rubocop from environment variable.
  # @api private
  class ArgumentsEnv
    def self.read_as_arguments
      if (arguments = ENV.fetch('RUBOCOP_OPTS', '')).empty?
        []
      else
        require 'shellwords'

        Shellwords.split(arguments)
      end
    end
  end
end
