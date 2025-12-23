# frozen_string_literal: true

module TestProf
  # Extend String with #parameterize method
  module StringParameterize
    refine String do
      # Replaces special characters in a string with dashes.
      def parameterize(separator: "-", preserve_case: false)
        gsub(/[^a-z0-9\-_]+/i, separator).tap do |str|
          str.downcase! unless preserve_case
        end
      end
    end
  end
end
