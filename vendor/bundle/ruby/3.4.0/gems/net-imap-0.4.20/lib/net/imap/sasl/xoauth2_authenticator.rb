# frozen_string_literal: true

# Authenticator for the "+XOAUTH2+" SASL mechanism.  This mechanism was
# originally created for GMail and widely adopted by hosted email providers.
# +XOAUTH2+ has been documented by
# Google[https://developers.google.com/gmail/imap/xoauth2-protocol] and
# Microsoft[https://learn.microsoft.com/en-us/exchange/client-developer/legacy-protocols/how-to-authenticate-an-imap-pop-smtp-application-by-using-oauth].
#
# This mechanism requires an OAuth2 access token which has been authorized
# with the appropriate OAuth2 scopes to access the user's services.  Most of
# these scopes are not standardized---consult each service provider's
# documentation for their scopes.
#
# Although this mechanism was never standardized and has been obsoleted by
# "+OAUTHBEARER+", it is still very widely supported.
#
# See Net::IMAP::SASL::OAuthBearerAuthenticator.
class Net::IMAP::SASL::XOAuth2Authenticator

  # It is unclear from {Google's original XOAUTH2
  # documentation}[https://developers.google.com/gmail/imap/xoauth2-protocol],
  # whether "User" refers to the authentication identity (+authcid+) or the
  # authorization identity (+authzid+).  The authentication identity is
  # established for the client by the OAuth token, so it seems that +username+
  # must be the authorization identity.
  #
  # {Microsoft's documentation for shared
  # mailboxes}[https://learn.microsoft.com/en-us/exchange/client-developer/legacy-protocols/how-to-authenticate-an-imap-pop-smtp-application-by-using-oauth#sasl-xoauth2-authentication-for-shared-mailboxes-in-office-365]
  # _clearly_ indicates that the Office 365 server interprets it as the
  # authorization identity.
  #
  # Although they _should_ validate that the token has been authorized to access
  # the service for +username+, _some_ servers appear to ignore this field,
  # relying only the identity and scope authorized by the token.
  attr_reader :username

  # Note that, unlike most other authenticators, #username is an alias for the
  # authorization identity and not the authentication identity.  The
  # authenticated identity is established for the client by the #oauth2_token.
  alias authzid username

  # An OAuth2 access token which has been authorized with the appropriate OAuth2
  # scopes to use the service for #username.
  attr_reader :oauth2_token
  alias secret oauth2_token

  # :call-seq:
  #   new(username,  oauth2_token,  **) -> authenticator
  #   new(username:, oauth2_token:, **) -> authenticator
  #   new(authzid:,  oauth2_token:, **) -> authenticator
  #
  # Creates an Authenticator for the "+XOAUTH2+" SASL mechanism, as specified by
  # Google[https://developers.google.com/gmail/imap/xoauth2-protocol],
  # Microsoft[https://learn.microsoft.com/en-us/exchange/client-developer/legacy-protocols/how-to-authenticate-an-imap-pop-smtp-application-by-using-oauth]
  # and Yahoo[https://senders.yahooinc.com/developer/documentation].
  #
  # === Properties
  #
  # * #username --- the username for the account being accessed.
  #
  #   #authzid  --- an alias for #username.
  #
  #   Note that, unlike some other authenticators, +username+ sets the
  #   _authorization_ identity and not the _authentication_ identity.  The
  #   authenticated identity is established for the client with the OAuth token.
  #
  # * #oauth2_token --- An OAuth2.0 access token which is authorized to access
  #   the service for #username.
  #
  # Any other keyword parameters are quietly ignored.
  def initialize(user = nil, token = nil, username: nil, oauth2_token: nil,
                 authzid: nil, secret: nil, **)
    @username = authzid || username || user or
      raise ArgumentError, "missing username (authzid)"
    @oauth2_token = oauth2_token || secret || token or
      raise ArgumentError, "missing oauth2_token"
    @done = false
  end

  # :call-seq:
  #   initial_response? -> true
  #
  # +XOAUTH2+ can send an initial client response.
  def initial_response?; true end

  # Returns the XOAUTH2 formatted response, which combines the +username+
  # with the +oauth2_token+.
  def process(_data)
    build_oauth2_string(@username, @oauth2_token)
  ensure
    @done = true
  end

  # Returns true when the initial client response was sent.
  #
  # The authentication should not succeed unless this returns true, but it
  # does *not* indicate success.
  def done?; @done end

  private

  def build_oauth2_string(username, oauth2_token)
    format("user=%s\1auth=Bearer %s\1\1", username, oauth2_token)
  end

end
