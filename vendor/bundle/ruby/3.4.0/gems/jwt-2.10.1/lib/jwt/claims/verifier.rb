# frozen_string_literal: true

module JWT
  module Claims
    # @api private
    module Verifier
      VERIFIERS = {
        exp: ->(options) { Claims::Expiration.new(leeway: options.dig(:exp, :leeway)) },
        nbf: ->(options) { Claims::NotBefore.new(leeway: options.dig(:nbf, :leeway)) },
        iss: ->(options) { Claims::Issuer.new(issuers: options[:iss]) },
        iat: ->(*)       { Claims::IssuedAt.new },
        jti: ->(options) { Claims::JwtId.new(validator: options[:jti]) },
        aud: ->(options) { Claims::Audience.new(expected_audience: options[:aud]) },
        sub: ->(options) { Claims::Subject.new(expected_subject: options[:sub]) },
        crit: ->(options) { Claims::Crit.new(expected_crits: options[:crit]) },
        required: ->(options) { Claims::Required.new(required_claims: options[:required]) },
        numeric: ->(*)        { Claims::Numeric.new }
      }.freeze

      private_constant(:VERIFIERS)

      class << self
        # @api private
        def verify!(context, *options)
          iterate_verifiers(*options) do |verifier, verifier_options|
            verify_one!(context, verifier, verifier_options)
          end
          nil
        end

        # @api private
        def errors(context, *options)
          errors = []
          iterate_verifiers(*options) do |verifier, verifier_options|
            verify_one!(context, verifier, verifier_options)
          rescue ::JWT::DecodeError => e
            errors << Error.new(message: e.message)
          end
          errors
        end

        private

        def iterate_verifiers(*options)
          options.each do |element|
            if element.is_a?(Hash)
              element.each_key { |key| yield(key, element) }
            else
              yield(element, {})
            end
          end
        end

        def verify_one!(context, verifier, options)
          verifier_builder = VERIFIERS.fetch(verifier) { raise ArgumentError, "#{verifier} not a valid claim verifier" }
          verifier_builder.call(options || {}).verify!(context: context)
        end
      end
    end
  end
end
