require 'base64'

# Extracts Keycloak realm roles from an OmniAuth OIDC auth hash.
# Roles come from the id_token/userinfo claims and, when present, the access token payload.
class Keycloak::RoleExtractor
  def initialize(auth_hash)
    @auth_hash = auth_hash
  end

  def roles
    stored = Array(@auth_hash['keycloak_roles'])
    (stored + claim_sources.flat_map { |claims| roles_from(claims) }).map(&:to_s).uniq
  end

  private

  def claim_sources
    [@auth_hash.dig('extra', 'raw_info'), access_token_claims].compact.map { |claims| claims.to_h.with_indifferent_access }
  end

  def roles_from(claims)
    Array(claims.dig(:realm_access, :roles)) + Array(claims[:roles])
  end

  # The access token is received over the back channel from the token endpoint, so its payload is read without re-verifying the signature.
  def access_token_claims
    token = @auth_hash.dig('credentials', 'token').to_s
    payload = token.split('.')[1]
    return nil if payload.blank?

    JSON.parse(Base64.urlsafe_decode64(payload + ('=' * ((4 - (payload.length % 4)) % 4))))
  rescue JSON::ParserError, ArgumentError
    nil
  end
end
