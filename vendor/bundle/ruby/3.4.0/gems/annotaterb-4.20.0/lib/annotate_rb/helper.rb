# frozen_string_literal: true

module AnnotateRb
  module Helper
    class << self
      def width(string)
        string.chars.inject(0) { |acc, elem| acc + ((elem.bytesize == 3) ? 2 : 1) }
      end

      # TODO: Find another implementation that doesn't depend on ActiveSupport
      def fallback(*args)
        args.compact.detect(&:present?)
      end
    end
  end
end
