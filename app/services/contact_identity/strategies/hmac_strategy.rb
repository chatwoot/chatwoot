# Checks that the identifier hash is the HMAC of the identifier, signed with the channel's secret.
# The caller decides which identifier the request has to prove.
class ContactIdentity::Strategies::HmacStrategy < ContactIdentity::Strategies::BaseStrategy
  DIGEST = 'sha256'.freeze

  def presented?
    params[:identifier_hash].present?
  end

  def verify
    return ContactIdentity::Proof.invalid unless ActiveSupport::SecurityUtils.secure_compare(params[:identifier_hash].to_s, expected_hash)

    ContactIdentity::Proof.verified(identifier: identifier.to_s)
  end

  private

  def expected_hash
    OpenSSL::HMAC.hexdigest(DIGEST, channel.hmac_token, identifier.to_s)
  end
end
