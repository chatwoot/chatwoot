# frozen_string_literal: true

module JWT
  module Claims
    # @api private
    module VerificationMethods
      def verify_claims!(*options)
        Verifier.verify!(self, *options)
      end

      def claim_errors(*options)
        Verifier.errors(self, *options)
      end

      def valid_claims?(*options)
        claim_errors(*options).empty?
      end
    end
  end
end
