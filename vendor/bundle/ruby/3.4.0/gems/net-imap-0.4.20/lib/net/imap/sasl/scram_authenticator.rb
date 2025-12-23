# frozen_string_literal: true

require "openssl"
require "securerandom"

require_relative "gs2_header"
require_relative "scram_algorithm"

module Net
  class IMAP
    module SASL

      # Abstract base class for the "+SCRAM-*+" family of SASL mechanisms,
      # defined in RFC5802[https://tools.ietf.org/html/rfc5802].  Use via
      # Net::IMAP#authenticate.
      #
      # Directly supported:
      # * +SCRAM-SHA-1+   --- ScramSHA1Authenticator
      # * +SCRAM-SHA-256+ --- ScramSHA256Authenticator
      #
      # New +SCRAM-*+ mechanisms can easily be added for any hash algorithm
      # supported by
      # OpenSSL::Digest[https://ruby.github.io/openssl/OpenSSL/Digest.html].
      # Subclasses need only set an appropriate +DIGEST_NAME+ constant.
      #
      # === SCRAM algorithm
      #
      # See the documentation and method definitions on ScramAlgorithm for an
      # overview of the algorithm.  The different mechanisms differ only by
      # which hash function that is used (or by support for channel binding with
      # +-PLUS+).
      #
      # See also the methods on GS2Header.
      #
      # ==== Server messages
      #
      # As server messages are received, they are validated and loaded into
      # the various attributes, e.g: #snonce, #salt, #iterations, #verifier,
      # #server_error, etc.
      #
      # Unlike many other SASL mechanisms, the +SCRAM-*+ family supports mutual
      # authentication and can return server error data in the server messages.
      # If #process raises an Error for the server-final-message, then
      # server_error may contain error details.
      #
      # === TLS Channel binding
      #
      # <em>The <tt>SCRAM-*-PLUS</tt> mechanisms and channel binding are not
      # supported yet.</em>
      #
      # === Caching SCRAM secrets
      #
      # <em>Caching of salted_password, client_key, stored_key, and server_key
      # is not supported yet.</em>
      #
      class ScramAuthenticator
        include GS2Header
        include ScramAlgorithm

        # :call-seq:
        #   new(username,  password,  **options) -> auth_ctx
        #   new(username:, password:, **options) -> auth_ctx
        #   new(authcid:,  password:, **options) -> auth_ctx
        #
        # Creates an authenticator for one of the "+SCRAM-*+" SASL mechanisms.
        # Each subclass defines #digest to match a specific mechanism.
        #
        # Called by Net::IMAP#authenticate and similar methods on other clients.
        #
        # === Parameters
        #
        # * #authcid  ― Identity whose #password is used.
        #
        #   #username - An alias for #authcid.
        # * #password ― Password or passphrase associated with this #username.
        # * _optional_ #authzid ― Alternate identity to act as or on behalf of.
        # * _optional_ #min_iterations - Overrides the default value (4096).
        #
        # Any other keyword parameters are quietly ignored.
        def initialize(username_arg = nil, password_arg = nil,
                       authcid: nil, username: nil,
                       authzid: nil,
                       password: nil, secret: nil,
                       min_iterations: 4096, # see both RFC5802 and RFC7677
                       cnonce: nil, # must only be set in tests
                       **options)
          @username = username || username_arg || authcid or
            raise ArgumentError, "missing username (authcid)"
          @password = password || secret || password_arg or
            raise ArgumentError, "missing password"
          @authzid = authzid

          @min_iterations = Integer min_iterations
          @min_iterations.positive? or
            raise ArgumentError, "min_iterations must be positive"

          @cnonce = cnonce || SecureRandom.base64(32)
        end

        # Authentication identity: the identity that matches the #password.
        #
        # RFC-2831[https://tools.ietf.org/html/rfc2831] uses the term +username+.
        # "Authentication identity" is the generic term used by
        # RFC-4422[https://tools.ietf.org/html/rfc4422].
        # RFC-4616[https://tools.ietf.org/html/rfc4616] and many later RFCs abbreviate
        # this to +authcid+.
        attr_reader :username
        alias authcid username

        # A password or passphrase that matches the #username.
        attr_reader :password
        alias secret password

        # Authorization identity: an identity to act as or on behalf of.  The
        # identity form is application protocol specific.  If not provided or
        # left blank, the server derives an authorization identity from the
        # authentication identity.  For example, an administrator or superuser
        # might take on another role:
        #
        #     imap.authenticate "SCRAM-SHA-256", "root", passwd, authzid: "user"
        #
        # The server is responsible for verifying the client's credentials and
        # verifying that the identity it associates with the client's
        # authentication identity is allowed to act as (or on behalf of) the
        # authorization identity.
        attr_reader :authzid

        # The minimal allowed iteration count.  Lower #iterations will raise an
        # Error.
        attr_reader :min_iterations

        # The client nonce, generated by SecureRandom
        attr_reader :cnonce

        # The server nonce, which must start with #cnonce
        attr_reader :snonce

        # The salt used by the server for this user
        attr_reader :salt

        # The iteration count for the selected hash function and user
        attr_reader :iterations

        # An error reported by the server during the \SASL exchange.
        #
        # Does not include errors reported by the protocol, e.g.
        # Net::IMAP::NoResponseError.
        attr_reader :server_error

        # Returns a new OpenSSL::Digest object, set to the appropriate hash
        # function for the chosen mechanism.
        #
        # <em>The class's +DIGEST_NAME+ constant must be set to the name of an
        # algorithm supported by OpenSSL::Digest.</em>
        def digest; OpenSSL::Digest.new self.class::DIGEST_NAME end

        # See {RFC5802 §7}[https://www.rfc-editor.org/rfc/rfc5802#section-7]
        # +client-first-message+.
        def initial_client_response
          "#{gs2_header}#{client_first_message_bare}"
        end

        # responds to the server's challenges
        def process(challenge)
          case (@state ||= :initial_client_response)
          when :initial_client_response
            initial_client_response.tap { @state = :server_first_message }
          when :server_first_message
            recv_server_first_message challenge
            final_message_with_proof.tap { @state = :server_final_message }
          when :server_final_message
            recv_server_final_message challenge
            "".tap { @state = :done }
          else
            raise Error, "server sent after complete, %p" % [challenge]
          end
        rescue Exception => ex
          @state = ex
          raise
        end

        # Is the authentication exchange complete?
        #
        # If false, another server continuation is required.
        def done?; @state == :done end

        private

        # Need to store this for auth_message
        attr_reader :server_first_message

        def format_message(hash) hash.map { _1.join("=") }.join(",") end

        def recv_server_first_message(server_first_message)
          @server_first_message = server_first_message
          sparams = parse_challenge server_first_message
          @snonce = sparams["r"] or
            raise Error, "server did not send nonce"
          @salt = sparams["s"]&.unpack1("m") or
            raise Error, "server did not send salt"
          @iterations = sparams["i"]&.then {|i| Integer i } or
            raise Error, "server did not send iteration count"
          min_iterations <= iterations or
            raise Error, "too few iterations: %d" % [iterations]
          mext = sparams["m"] and
            raise Error, "mandatory extension: %p" % [mext]
          snonce.start_with? cnonce or
            raise Error, "invalid server nonce"
        end

        def recv_server_final_message(server_final_message)
          sparams = parse_challenge server_final_message
          @server_error = sparams["e"] and
            raise Error, "server error: %s" % [server_error]
          verifier = sparams["v"].unpack1("m") or
            raise Error, "server did not send verifier"
          verifier == server_signature or
            raise Error, "server verify failed: %p != %p" % [
              server_signature, verifier
            ]
        end

        # See {RFC5802 §7}[https://www.rfc-editor.org/rfc/rfc5802#section-7]
        # +client-first-message-bare+.
        def client_first_message_bare
          @client_first_message_bare ||=
            format_message(n: gs2_saslname_encode(SASL.saslprep(username)),
                           r: cnonce)
        end

        # See {RFC5802 §7}[https://www.rfc-editor.org/rfc/rfc5802#section-7]
        # +client-final-message+.
        def final_message_with_proof
          proof = [client_proof].pack("m0")
          "#{client_final_message_without_proof},p=#{proof}"
        end

        # See {RFC5802 §7}[https://www.rfc-editor.org/rfc/rfc5802#section-7]
        # +client-final-message-without-proof+.
        def client_final_message_without_proof
          @client_final_message_without_proof ||=
            format_message(c: [cbind_input].pack("m0"), # channel-binding
                           r: snonce)                   # nonce
        end

        # See {RFC5802 §7}[https://www.rfc-editor.org/rfc/rfc5802#section-7]
        # +cbind-input+.
        #
        # >>>
        #   *TODO:* implement channel binding, appending +cbind-data+ here.
        alias cbind_input gs2_header

        # RFC5802 specifies "that the order of attributes in client or server
        # messages is fixed, with the exception of extension attributes", but
        # this parses it simply as a hash, without respect to order.  Note that
        # repeated keys (violating the spec) will use the last value.
        def parse_challenge(challenge)
          challenge.split(/,/).to_h {|pair| pair.split(/=/, 2) }
        rescue ArgumentError
          raise Error, "unparsable challenge: %p" % [challenge]
        end

      end

      # Authenticator for the "+SCRAM-SHA-1+" SASL mechanism, defined in
      # RFC5802[https://tools.ietf.org/html/rfc5802].
      #
      # Uses the "SHA-1" digest algorithm from OpenSSL::Digest.
      #
      # See ScramAuthenticator.
      class ScramSHA1Authenticator < ScramAuthenticator
        DIGEST_NAME = "SHA1"
      end

      # Authenticator for the "+SCRAM-SHA-256+" SASL mechanism, defined in
      # RFC7677[https://tools.ietf.org/html/rfc7677].
      #
      # Uses the "SHA-256" digest algorithm from OpenSSL::Digest.
      #
      # See ScramAuthenticator.
      class ScramSHA256Authenticator < ScramAuthenticator
        DIGEST_NAME = "SHA256"
      end

    end
  end
end
