# frozen_string_literal: true

module JWT
  # The EncodeError class is raised when there is an error encoding a JWT.
  class EncodeError < StandardError; end

  # The DecodeError class is raised when there is an error decoding a JWT.
  class DecodeError < StandardError; end

  # The RequiredDependencyError class is raised when a required dependency is missing.
  class RequiredDependencyError < StandardError; end

  # The VerificationError class is raised when there is an error verifying a JWT.
  class VerificationError < DecodeError; end

  # The ExpiredSignature class is raised when the JWT signature has expired.
  class ExpiredSignature < DecodeError; end

  # The IncorrectAlgorithm class is raised when the JWT algorithm is incorrect.
  class IncorrectAlgorithm < DecodeError; end

  # The ImmatureSignature class is raised when the JWT signature is immature.
  class ImmatureSignature < DecodeError; end

  # The InvalidIssuerError class is raised when the JWT issuer is invalid.
  class InvalidIssuerError < DecodeError; end

  # The UnsupportedEcdsaCurve class is raised when the ECDSA curve is unsupported.
  class UnsupportedEcdsaCurve < IncorrectAlgorithm; end

  # The InvalidIatError class is raised when the JWT issued at (iat) claim is invalid.
  class InvalidIatError < DecodeError; end

  # The InvalidAudError class is raised when the JWT audience (aud) claim is invalid.
  class InvalidAudError < DecodeError; end

  # The InvalidSubError class is raised when the JWT subject (sub) claim is invalid.
  class InvalidSubError < DecodeError; end

  # The InvalidCritError class is raised when the JWT crit header is invalid.
  class InvalidCritError < DecodeError; end

  # The InvalidJtiError class is raised when the JWT ID (jti) claim is invalid.
  class InvalidJtiError < DecodeError; end

  # The InvalidPayload class is raised when the JWT payload is invalid.
  class InvalidPayload < DecodeError; end

  # The MissingRequiredClaim class is raised when a required claim is missing from the JWT.
  class MissingRequiredClaim < DecodeError; end

  # The Base64DecodeError class is raised when there is an error decoding a Base64-encoded string.
  class Base64DecodeError < DecodeError; end

  # The JWKError class is raised when there is an error with the JSON Web Key (JWK).
  class JWKError < DecodeError; end
end
