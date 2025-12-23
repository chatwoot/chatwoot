# frozen_string_literal: true

module RuboCop
  # This is a class that reads optional command line arguments to rubocop from .rubocop file.
  # @api private
  class ArgumentsFile
    def self.read_as_arguments
      if File.exist?('.rubocop') && !File.directory?('.rubocop')
        require 'shellwords'

        File.read('.rubocop').shellsplit
      else
        []
      end
    end
  end
end
