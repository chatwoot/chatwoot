# frozen_string_literal: true

# Authenticator for the "+LOGIN+" SASL mechanism.  See Net::IMAP#authenticate.
#
# +LOGIN+ authentication sends the password in cleartext.
# RFC3501[https://tools.ietf.org/html/rfc3501] encourages servers to disable
# cleartext authentication until after TLS has been negotiated.
# RFC8314[https://tools.ietf.org/html/rfc8314] recommends TLS version 1.2 or
# greater be used for all traffic, and deprecate cleartext access ASAP.  +LOGIN+
# can be secured by TLS encryption.
#
# == Deprecated
#
# The {SASL mechanisms
# registry}[https://www.iana.org/assignments/sasl-mechanisms/sasl-mechanisms.xhtml]
# marks "LOGIN" as obsoleted in favor of "PLAIN".  It is included here for
# compatibility with existing servers.  See
# {draft-murchison-sasl-login}[https://www.iana.org/go/draft-murchison-sasl-login]
# for both specification and deprecation.
class Net::IMAP::SASL::LoginAuthenticator
  STATE_USER = :USER
  STATE_PASSWORD = :PASSWORD
  STATE_DONE = :DONE
  private_constant :STATE_USER, :STATE_PASSWORD, :STATE_DONE

  def initialize(user = nil, pass = nil,
                 authcid: nil, username: nil,
                 password: nil, secret: nil,
                 warn_deprecation: true,
                 **)
    if warn_deprecation
      warn "WARNING: LOGIN SASL mechanism is deprecated. Use PLAIN instead."
    end
    @user = authcid || username || user
    @password = password || secret || pass
    @state = STATE_USER
  end

  def initial_response?; false end

  def process(data)
    case @state
    when STATE_USER
      @state = STATE_PASSWORD
      return @user
    when STATE_PASSWORD
      @state = STATE_DONE
      return @password
    when STATE_DONE
      raise ResponseParseError, data
    end
  end

  def done?; @state == STATE_DONE end
end
