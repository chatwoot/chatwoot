# frozen_string_literal: true

require_relative "gs2_header"

module Net
  class IMAP < Protocol
    module SASL

      # Abstract base class for the SASL mechanisms defined in
      # RFC7628[https://tools.ietf.org/html/rfc7628]:
      # * OAUTHBEARER[rdoc-ref:OAuthBearerAuthenticator]
      #   (OAuthBearerAuthenticator)
      # * OAUTH10A
      class OAuthAuthenticator
        include GS2Header

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

        # Hostname to which the client connected.  (optional)
        attr_reader :host

        # Service port to which the client connected.  (optional)
        attr_reader :port

        # HTTP method.  (optional)
        attr_reader :mthd

        # HTTP path data.  (optional)
        attr_reader :path

        # HTTP post data.  (optional)
        attr_reader :post

        # The query string.  (optional)
        attr_reader :qs
        alias query qs

        # Stores the most recent server "challenge".  When authentication fails,
        # this may hold information about the failure reason, as JSON.
        attr_reader :last_server_response

        # Creates an RFC7628[https://tools.ietf.org/html/rfc7628] OAuth
        # authenticator.
        #
        # ==== Parameters
        #
        # See child classes for required parameter(s).  The following parameters
        # are all optional, but it is worth noting that <b>application protocols
        # are allowed to require</b> #authzid (or other parameters, such as
        # #host or #port) <b>as are specific server implementations</b>.
        #
        # * _optional_ #authzid  ― Authorization identity to act as or on behalf of.
        #
        #   _optional_ #username — An alias for #authzid.
        #
        #   Note that, unlike some other authenticators, +username+ sets the
        #   _authorization_ identity and not the _authentication_ identity.  The
        #   authentication identity is established for the client by the OAuth
        #   token.
        #
        # * _optional_ #host — Hostname to which the client connected.
        # * _optional_ #port — Service port to which the client connected.
        # * _optional_ #mthd — HTTP method
        # * _optional_ #path — HTTP path data
        # * _optional_ #post — HTTP post data
        # * _optional_ #qs   — HTTP query string
        #
        #   _optional_ #query — An alias for #qs
        #
        # Any other keyword parameters are quietly ignored.
        def initialize(authzid: nil, host: nil, port: nil,
                       username: nil, query: nil,
                       mthd: nil, path: nil, post: nil, qs: nil, **)
          @authzid = authzid || username
          @host    = host
          @port    = port
          @mthd    = mthd
          @path    = path
          @post    = post
          @qs      = qs || query
          @done    = false
        end

        # The {RFC7628 §3.1}[https://www.rfc-editor.org/rfc/rfc7628#section-3.1]
        # formatted response.
        def initial_client_response
          kv_pairs = {
            host: host, port: port, mthd: mthd, path: path, post: post, qs: qs,
            auth: authorization, # authorization is implemented by subclasses
          }.compact
          [gs2_header, *kv_pairs.map {|kv| kv.join("=") }, "\1"].join("\1")
        end

        # Returns initial_client_response the first time, then "<tt>^A</tt>".
        def process(data)
          @last_server_response = data
          done? ? "\1" : initial_client_response
        ensure
          @done = true
        end

        # Returns true when the initial client response was sent.
        #
        # The authentication should not succeed unless this returns true, but it
        # does *not* indicate success.
        def done?; @done end

        # Value of the HTTP Authorization header
        #
        # <b>Implemented by subclasses.</b>
        def authorization; raise "must be implemented by subclass" end

      end

      # Authenticator for the "+OAUTHBEARER+" SASL mechanism, specified in
      # RFC7628[https://tools.ietf.org/html/rfc7628].  Authenticates using OAuth
      # 2.0 bearer tokens, as described in
      # RFC6750[https://tools.ietf.org/html/rfc6750].  Use via
      # Net::IMAP#authenticate.
      #
      # RFC6750[https://tools.ietf.org/html/rfc6750] requires Transport Layer
      # Security (TLS) to secure the protocol interaction between the client and
      # the resource server.  TLS _MUST_ be used for +OAUTHBEARER+ to protect
      # the bearer token.
      class OAuthBearerAuthenticator < OAuthAuthenticator

        # An OAuth 2.0 bearer token.  See {RFC-6750}[https://www.rfc-editor.org/rfc/rfc6750]
        attr_reader :oauth2_token
        alias secret oauth2_token

        # :call-seq:
        #   new(oauth2_token,          **options) -> authenticator
        #   new(authzid, oauth2_token, **options) -> authenticator
        #   new(oauth2_token:,         **options) -> authenticator
        #
        # Creates an Authenticator for the "+OAUTHBEARER+" SASL mechanism.
        #
        # Called by Net::IMAP#authenticate and similar methods on other clients.
        #
        # ==== Parameters
        #
        # * #oauth2_token — An OAuth2 bearer token
        #
        # All other keyword parameters are passed to
        # {super}[rdoc-ref:OAuthAuthenticator::new] (see OAuthAuthenticator).
        # The most common ones are:
        #
        # * _optional_ #authzid  ― Authorization identity to act as or on behalf of.
        #
        #   _optional_ #username — An alias for #authzid.
        #
        #   Note that, unlike some other authenticators, +username+ sets the
        #   _authorization_ identity and not the _authentication_ identity.  The
        #   authentication identity is established for the client by
        #   #oauth2_token.
        #
        # * _optional_ #host — Hostname to which the client connected.
        # * _optional_ #port — Service port to which the client connected.
        #
        # Although only oauth2_token is required by this mechanism, it is worth
        # noting that <b><em>application protocols are allowed to
        # require</em></b> #authzid (<em>or other parameters, such as</em> #host
        # _or_ #port) <b><em>as are specific server implementations</em></b>.
        def initialize(arg1 = nil, arg2 = nil,
                       oauth2_token: nil, secret: nil,
                       **args, &blk)
          username, oauth2_token_arg = arg2.nil? ? [nil, arg1] : [arg1, arg2]
          super(username: username, **args, &blk)
          @oauth2_token = oauth2_token || secret || oauth2_token_arg or
            raise ArgumentError, "missing oauth2_token"
        end

        # :call-seq:
        #   initial_response? -> true
        #
        # +OAUTHBEARER+ sends an initial client response.
        def initial_response?; true end

        # Value of the HTTP Authorization header
        def authorization; "Bearer #{oauth2_token}" end

      end
    end

  end
end
