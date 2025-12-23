# frozen_string_literal: true

module Byebug
  module Helpers
    #
    # Utilities for interaction with strings
    #
    module StringHelper
      #
      # Converts +str+ from an_underscored-or-dasherized_string to
      # ACamelizedString.
      #
      def camelize(str)
        str.dup.split(/[_-]/).map(&:capitalize).join("")
      end

      #
      # Improves indentation and spacing in +str+ for readability in Byebug's
      # command prompt.
      #
      def prettify(str)
        "\n" + deindent(str) + "\n"
      end

      #
      # Removes a number of leading whitespace for each input line.
      #
      def deindent(str, leading_spaces: 6)
        str.gsub(/^ {#{leading_spaces}}/, "")
      end
    end
  end
end
