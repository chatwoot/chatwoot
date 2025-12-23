# frozen_string_literal: true

module Prism
  module Translation
    # This class is the entry-point for Ruby 3.3 of `Prism::Translation::Parser`.
    class Parser33 < Parser
      def version # :nodoc:
        33
      end
    end
  end
end
