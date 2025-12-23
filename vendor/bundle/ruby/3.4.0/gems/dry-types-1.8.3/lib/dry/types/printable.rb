# frozen_string_literal: true

module Dry
  module Types
    # @api private
    module Printable
      # @return [String]
      #
      # @api private
      def to_s = PRINTER.(self)
      alias_method :inspect, :to_s
    end
  end
end
