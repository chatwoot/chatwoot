# frozen_string_literal: true

module AnnotateRb
  module Commands
    class PrintVersion
      def call(_options)
        puts "AnnotateRb v#{Core.version}"
      end
    end
  end
end
