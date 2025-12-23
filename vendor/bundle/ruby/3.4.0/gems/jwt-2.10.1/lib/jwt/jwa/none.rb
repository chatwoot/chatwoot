# frozen_string_literal: true

module JWT
  module JWA
    # Implementation of the none algorithm
    class None
      include JWT::JWA::SigningAlgorithm

      def initialize
        @alg = 'none'
      end

      def sign(*)
        ''
      end

      def verify(*)
        true
      end

      register_algorithm(new)
    end
  end
end
