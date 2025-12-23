# frozen_string_literal: true

module Net
  class IMAP < Protocol
    module SASL

      # Authenticator for the "+EXTERNAL+" SASL mechanism, as specified by
      # RFC-4422[https://tools.ietf.org/html/rfc4422].  See
      # Net::IMAP#authenticate.
      #
      # The EXTERNAL mechanism requests that the server use client credentials
      # established external to SASL, for example by TLS certificate or IPSec.
      class ExternalAuthenticator

        # Authorization identity: an identity to act as or on behalf of.  The
        # identity form is application protocol specific.  If not provided or
        # left blank, the server derives an authorization identity from the
        # authentication identity.  The server is responsible for verifying the
        # client's credentials and verifying that the identity it associates
        # with the client's authentication identity is allowed to act as (or on
        # behalf of) the authorization identity.
        #
        # For example, an administrator or superuser might take on another role:
        #
        #     imap.authenticate "PLAIN", "root", passwd, authzid: "user"
        #
        attr_reader :authzid
        alias username authzid

        # :call-seq:
        #   new(authzid: nil, **) -> authenticator
        #   new(username: nil, **) -> authenticator
        #   new(username = nil, **) -> authenticator
        #
        # Creates an Authenticator for the "+EXTERNAL+" SASL mechanism, as
        # specified in RFC-4422[https://tools.ietf.org/html/rfc4422].  To use
        # this, see Net::IMAP#authenticate or your client's authentication
        # method.
        #
        # ==== Parameters
        #
        # * _optional_ #authzid  ― Authorization identity to act as or on behalf of.
        #
        #   _optional_ #username ― An alias for #authzid.
        #
        #   Note that, unlike some other authenticators, +username+ sets the
        #   _authorization_ identity and not the _authentication_ identity.  The
        #   authentication identity is established for the client by the
        #   external credentials.
        #
        # Any other keyword parameters are quietly ignored.
        def initialize(user = nil, authzid: nil, username: nil, **)
          authzid ||= username || user
          @authzid = authzid&.to_str&.encode "UTF-8"
          if @authzid&.match?(/\u0000/u) # also validates UTF8 encoding
            raise ArgumentError, "contains NULL"
          end
          @done = false
        end

        # :call-seq:
        #   initial_response? -> true
        #
        # +EXTERNAL+ can send an initial client response.
        def initial_response?; true end

        # Returns #authzid, or an empty string if there is no authzid.
        def process(_)
          authzid || ""
        ensure
          @done = true
        end

        # Returns true when the initial client response was sent.
        #
        # The authentication should not succeed unless this returns true, but it
        # does *not* indicate success.
        def done?; @done end

      end
    end
  end
end
