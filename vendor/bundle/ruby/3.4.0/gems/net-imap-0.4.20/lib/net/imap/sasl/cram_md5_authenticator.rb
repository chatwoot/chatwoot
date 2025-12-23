# frozen_string_literal: true

# Authenticator for the "+CRAM-MD5+" SASL mechanism, specified in
# RFC2195[https://tools.ietf.org/html/rfc2195].  See Net::IMAP#authenticate.
#
# == Deprecated
#
# +CRAM-MD5+ is obsolete and insecure.  It is included for compatibility with
# existing servers.
# {draft-ietf-sasl-crammd5-to-historic}[https://tools.ietf.org/html/draft-ietf-sasl-crammd5-to-historic-00.html]
# recommends using +SCRAM-*+ or +PLAIN+ protected by TLS instead.
#
# Additionally, RFC8314[https://tools.ietf.org/html/rfc8314] discourage the use
# of cleartext and recommends TLS version 1.2 or greater be used for all
# traffic.  With TLS +CRAM-MD5+ is okay, but so is +PLAIN+
class Net::IMAP::SASL::CramMD5Authenticator
  def initialize(user = nil, pass = nil,
                 authcid: nil, username: nil,
                 password: nil, secret: nil,
                 warn_deprecation: true,
                 **)
    if warn_deprecation
      warn "WARNING: CRAM-MD5 mechanism is deprecated." # TODO: recommend SCRAM
    end
    require "digest/md5"
    @user = authcid || username || user
    @password = password || secret || pass
    @done = false
  end

  def initial_response?; false end

  def process(challenge)
    digest = hmac_md5(challenge, @password)
    return @user + " " + digest
  ensure
    @done = true
  end

  def done?; @done end

  private

  def hmac_md5(text, key)
    if key.length > 64
      key = Digest::MD5.digest(key)
    end

    k_ipad = key + "\0" * (64 - key.length)
    k_opad = key + "\0" * (64 - key.length)
    for i in 0..63
      k_ipad[i] = (k_ipad[i].ord ^ 0x36).chr
      k_opad[i] = (k_opad[i].ord ^ 0x5c).chr
    end

    digest = Digest::MD5.digest(k_ipad + text)

    return Digest::MD5.hexdigest(k_opad + digest)
  end

end
