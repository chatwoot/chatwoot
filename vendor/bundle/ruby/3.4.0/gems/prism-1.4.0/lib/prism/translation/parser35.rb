# frozen_string_literal: true

module Prism
  module Translation
    # This class is the entry-point for Ruby 3.5 of `Prism::Translation::Parser`.
    class Parser35 < Parser
      def version # :nodoc:
        35
      end
    end
  end
end
