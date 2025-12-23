# frozen_string_literal: true

module Dry
  class CLI
    # @api private
    # @since 0.5.0
    module Inflector
      # @api private
      # @since 0.5.0
      def self.dasherize(input)
        return nil unless input

        input.to_s.downcase.gsub(/[[[:space:]]_]/, "-")
      end
    end
  end
end
