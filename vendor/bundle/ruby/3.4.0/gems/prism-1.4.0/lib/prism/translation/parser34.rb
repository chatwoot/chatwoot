# frozen_string_literal: true

module Prism
  module Translation
    # This class is the entry-point for Ruby 3.4 of `Prism::Translation::Parser`.
    class Parser34 < Parser
      def version # :nodoc:
        34
      end
    end
  end
end
