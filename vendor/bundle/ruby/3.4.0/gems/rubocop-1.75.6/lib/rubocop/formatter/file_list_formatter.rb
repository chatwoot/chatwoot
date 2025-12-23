# frozen_string_literal: true

module RuboCop
  module Formatter
    # This formatter displays just a list of the files with offenses in them,
    # separated by newlines. The output is machine-parsable.
    #
    # Here's the format:
    #
    # /some/file
    # /some/other/file
    class FileListFormatter < BaseFormatter
      def file_finished(file, offenses)
        return if offenses.empty?

        output.printf("%<path>s\n", path: file)
      end
    end
  end
end
