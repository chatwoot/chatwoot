# frozen_string_literal: true

module Rack
  class Attack
    class Safelist < Check
      def initialize(name = nil, &block)
        super
        @type = :safelist
      end
    end
  end
end
