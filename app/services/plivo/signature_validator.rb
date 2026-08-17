class Plivo::SignatureValidator
  # Recomputes Plivo's V3 request signature and compares it against the header.
  # Base string is the exact posted URL, a sorted concatenation of the body
  # parameters, and the nonce, keyed by the Auth Token with HMAC-SHA256.
  # Ported from the verified Plivo Kestra plugin implementation.
  # https://www.plivo.com/docs/messaging/concepts/validate-signature/
  pattr_initialize [:auth_token!, :url!, :params!, :nonce!, :signature!]

  def valid?
    return false if auth_token.blank? || url.blank? || nonce.blank? || signature.blank?

    ActiveSupport::SecurityUtils.secure_compare(computed_signature, signature)
  end

  private

  def computed_signature
    base = +url
    if params.present?
      base << '?'
      params.sort_by { |key, _| key.to_s }.each { |key, value| base << "#{key}#{value}" }
    end
    base << ".#{nonce}"

    Base64.strict_encode64(OpenSSL::HMAC.digest('sha256', auth_token, base))
  end
end
