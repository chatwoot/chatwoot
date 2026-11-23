# Checks a token that the business signed with one of the inbox's signing keys.
# The token carries the contact's identifier and details as claims.
class ContactIdentity::Strategies::JwtStrategy < ContactIdentity::Strategies::BaseStrategy
  ALGORITHM = 'HS256'.freeze
  ATTRIBUTE_CLAIMS = %w[name email phone_number avatar_url custom_attributes].freeze

  def presented?
    params[:identity_token].present?
  end

  def verify
    claims = verified_claims
    return ContactIdentity::Proof.invalid unless claims.is_a?(Hash)

    token_identifier = identifier_in(claims)
    return ContactIdentity::Proof.invalid if token_identifier.blank?

    ContactIdentity::Proof.verified(identifier: token_identifier, attributes: claims.slice(*ATTRIBUTE_CLAIMS))
  end

  private

  def verified_claims
    token = params[:identity_token]
    return unless token.is_a?(String)
    return if signing_secrets.empty?

    # The token does not name its key, so it is valid when any key of the inbox signed it.
    claims, _header = JWT.decode(token, signing_secrets, true, algorithm: ALGORITHM)
    claims
  rescue JWT::DecodeError
    nil
  end

  def signing_secrets
    @signing_secrets ||= channel.inbox.contact_identity_signing_keys.map(&:secret)
  end

  def identifier_in(claims)
    token_identifier = claims['identifier']
    return unless token_identifier.is_a?(String) || token_identifier.is_a?(Integer)

    token_identifier.to_s
  end
end
