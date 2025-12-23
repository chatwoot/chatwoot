# frozen_string_literal: true

require 'json'

module JWT
  # @api private
  class JSON
    class << self
      def generate(data)
        ::JSON.generate(data)
      end

      def parse(data)
        ::JSON.parse(data)
      end
    end
  end
end
