# frozen_string_literal: true

module Net
  class IMAP < Protocol
    module SASL

      # Originally defined for the GS2 mechanism family in
      # RFC5801[https://tools.ietf.org/html/rfc5801],
      # several different mechanisms start with a GS2 header:
      # * +GS2-*+       --- RFC5801[https://tools.ietf.org/html/rfc5801]
      # * +SCRAM-*+     --- RFC5802[https://tools.ietf.org/html/rfc5802]
      #   (ScramAuthenticator)
      # * +SAML20+      --- RFC6595[https://tools.ietf.org/html/rfc6595]
      # * +OPENID20+    --- RFC6616[https://tools.ietf.org/html/rfc6616]
      # * +OAUTH10A+    --- RFC7628[https://tools.ietf.org/html/rfc7628]
      # * +OAUTHBEARER+ --- RFC7628[https://tools.ietf.org/html/rfc7628]
      #   (OAuthBearerAuthenticator)
      #
      # Classes that include this module must implement +#authzid+.
      module GS2Header
        NO_NULL_CHARS = /\A[^\x00]+\z/u.freeze # :nodoc:

        ##
        # Matches {RFC5801 §4}[https://www.rfc-editor.org/rfc/rfc5801#section-4]
        # +saslname+.  The output from gs2_saslname_encode matches this Regexp.
        RFC5801_SASLNAME = /\A(?:[^,=\x00]|=2C|=3D)+\z/u.freeze

        # The {RFC5801 §4}[https://www.rfc-editor.org/rfc/rfc5801#section-4]
        # +gs2-header+, which prefixes the #initial_client_response.
        #
        # >>>
        #   <em>Note: the actual GS2 header includes an optional flag to
        #   indicate that the GSS mechanism is not "standard", but since all of
        #   the SASL mechanisms using GS2 are "standard", we don't include that
        #   flag.  A class for a nonstandard GSSAPI mechanism should prefix with
        #   "+F,+".</em>
        def gs2_header
          "#{gs2_cb_flag},#{gs2_authzid},"
        end

        # The {RFC5801 §4}[https://www.rfc-editor.org/rfc/rfc5801#section-4]
        # +gs2-cb-flag+:
        #
        # "+n+":: The client doesn't support channel binding.
        # "+y+":: The client does support channel binding
        #         but thinks the server does not.
        # "+p+":: The client requires channel binding.
        #         The selected channel binding follows "+p=+".
        #
        # The default always returns "+n+".  A mechanism that supports channel
        # binding must override this method.
        #
        def gs2_cb_flag; "n" end

        # The {RFC5801 §4}[https://www.rfc-editor.org/rfc/rfc5801#section-4]
        # +gs2-authzid+ header, when +#authzid+ is not empty.
        #
        # If +#authzid+ is empty or +nil+, an empty string is returned.
        def gs2_authzid
          return "" if authzid.nil? || authzid == ""
          "a=#{gs2_saslname_encode(authzid)}"
        end

        module_function

        # Encodes +str+ to match RFC5801_SASLNAME.
        def gs2_saslname_encode(str)
          str = str.encode("UTF-8")
          # Regexp#match raises "invalid byte sequence" for invalid UTF-8
          NO_NULL_CHARS.match str or
            raise ArgumentError, "invalid saslname: %p" % [str]
          str
            .gsub(?=, "=3D")
            .gsub(?,, "=2C")
        end

      end
    end
  end
end
