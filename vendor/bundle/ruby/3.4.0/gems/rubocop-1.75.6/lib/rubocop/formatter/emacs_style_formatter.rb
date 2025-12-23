# frozen_string_literal: true

module RuboCop
  module Formatter
    # This formatter displays the report data in format that's
    # easy to process in the Emacs text editor.
    # The output is machine-parsable.
    class EmacsStyleFormatter < BaseFormatter
      def file_finished(file, offenses)
        offenses.each do |o|
          output.printf(
            "%<path>s:%<line>d:%<column>d: %<severity>s: %<message>s\n",
            path: file,
            line: o.line,
            column: o.real_column,
            severity: o.severity.code,
            message: message(o)
          )
        end
      end

      private

      def message(offense)
        message =
          if offense.corrected_with_todo?
            "[Todo] #{offense.message}"
          elsif offense.corrected?
            "[Corrected] #{offense.message}"
          elsif offense.correctable?
            "[Correctable] #{offense.message}"
          else
            offense.message
          end
        message.tr("\n", ' ')
      end
    end
  end
end
