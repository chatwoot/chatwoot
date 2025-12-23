# frozen_string_literal: true

module AnnotateRb
  module Commands
    class PrintHelp
      def initialize(parser)
        @parser = parser
      end

      def call(_options)
        puts @parser.help
      end
    end
  end
end
