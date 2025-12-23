# frozen_string_literal: true

module JWT
  module JWA
    # Represents an unsupported algorithm
    module Unsupported
      class << self
        include JWT::JWA::SigningAlgorithm

        def sign(*)
          raise_sign_error!('Unsupported signing method')
        end

        def verify(*)
          raise JWT::VerificationError, 'Algorithm not supported'
        end
      end
    end
  end
end
