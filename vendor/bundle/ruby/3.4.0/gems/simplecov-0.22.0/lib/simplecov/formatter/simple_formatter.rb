# frozen_string_literal: true

module SimpleCov
  module Formatter
    #
    # A ridiculously simple formatter for SimpleCov results.
    #
    class SimpleFormatter
      # Takes a SimpleCov::Result and generates a string out of it
      def format(result)
        output = +""
        result.groups.each do |name, files|
          output << "Group: #{name}\n"
          output << "=" * 40
          output << "\n"
          files.each do |file|
            output << "#{file.filename} (coverage: #{file.covered_percent.round(2)}%)\n"
          end
          output << "\n"
        end
        output
      end
    end
  end
end
