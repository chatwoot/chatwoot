# frozen_string_literal: true

module JWT
  # JSON Web Algorithms
  module JWA
    # Base functionality for signing algorithms
    module SigningAlgorithm
      # Class methods for the SigningAlgorithm module
      module ClassMethods
        def register_algorithm(algo)
          ::JWT::JWA.register_algorithm(algo)
        end
      end

      def self.included(klass)
        klass.extend(ClassMethods)
        klass.include(JWT::JWA::Compat)
      end

      attr_reader :alg

      def valid_alg?(alg_to_check)
        alg&.casecmp(alg_to_check)&.zero? == true
      end

      def header(*)
        { 'alg' => alg }
      end

      def sign(*)
        raise_sign_error!('Algorithm implementation is missing the sign method')
      end

      def verify(*)
        raise_verify_error!('Algorithm implementation is missing the verify method')
      end

      def raise_verify_error!(message)
        raise(DecodeError.new(message).tap { |e| e.set_backtrace(caller(1)) })
      end

      def raise_sign_error!(message)
        raise(EncodeError.new(message).tap { |e| e.set_backtrace(caller(1)) })
      end
    end

    class << self
      def register_algorithm(algo)
        algorithms[algo.alg.to_s.downcase] = algo
      end

      def find(algo)
        algorithms.fetch(algo.to_s.downcase, Unsupported)
      end

      private

      def algorithms
        @algorithms ||= {}
      end
    end
  end
end
