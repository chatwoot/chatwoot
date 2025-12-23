# frozen_string_literal: true

module JWT
  module JWA
    # @api private
    class Wrapper
      include SigningAlgorithm

      def initialize(algorithm)
        @algorithm = algorithm
      end

      def alg
        return @algorithm.alg if @algorithm.respond_to?(:alg)

        super
      end

      def valid_alg?(alg_to_check)
        return @algorithm.valid_alg?(alg_to_check) if @algorithm.respond_to?(:valid_alg?)

        super
      end

      def header(*args, **kwargs)
        return @algorithm.header(*args, **kwargs) if @algorithm.respond_to?(:header)

        super
      end

      def sign(*args, **kwargs)
        return @algorithm.sign(*args, **kwargs) if @algorithm.respond_to?(:sign)

        super
      end

      def verify(*args, **kwargs)
        return @algorithm.verify(*args, **kwargs) if @algorithm.respond_to?(:verify)

        super
      end
    end
  end
end
