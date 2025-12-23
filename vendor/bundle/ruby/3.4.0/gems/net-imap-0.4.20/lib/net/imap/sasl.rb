# frozen_string_literal: true

module Net
  class IMAP

    # Pluggable authentication mechanisms for protocols which support SASL
    # (Simple Authentication and Security Layer), such as IMAP4, SMTP, LDAP, and
    # XMPP.  {RFC-4422}[https://tools.ietf.org/html/rfc4422] specifies the
    # common \SASL framework:
    # >>>
    #   SASL is conceptually a framework that provides an abstraction layer
    #   between protocols and mechanisms as illustrated in the following
    #   diagram.
    #
    #               SMTP    LDAP    XMPP   Other protocols ...
    #                  \       |    |      /
    #                   \      |    |     /
    #                  SASL abstraction layer
    #                   /      |    |     \
    #                  /       |    |      \
    #           EXTERNAL   GSSAPI  PLAIN   Other mechanisms ...
    #
    # Net::IMAP uses SASL via the Net::IMAP#authenticate method.
    #
    # == Mechanisms
    #
    # Each mechanism has different properties and requirements.  Please consult
    # the documentation for the specific mechanisms you are using:
    #
    # +ANONYMOUS+::
    #     See AnonymousAuthenticator.
    #
    #     Allows the user to gain access to public services or resources without
    #     authenticating or disclosing an identity.
    #
    # +EXTERNAL+::
    #     See ExternalAuthenticator.
    #
    #     Authenticates using already established credentials, such as a TLS
    #     certificate or IPSec.
    #
    # +OAUTHBEARER+::
    #     See OAuthBearerAuthenticator.
    #
    #     Login using an OAuth2 Bearer token.  This is the standard mechanism
    #     for using OAuth2 with \SASL, but it is not yet deployed as widely as
    #     +XOAUTH2+.
    #
    # +PLAIN+::
    #     See PlainAuthenticator.
    #
    #     Login using clear-text username and password.
    #
    # +SCRAM-SHA-1+::
    # +SCRAM-SHA-256+::
    #     See ScramAuthenticator.
    #
    #     Login by username and password.  The password is not sent to the
    #     server but is used in a salted challenge/response exchange.
    #     +SCRAM-SHA-1+ and +SCRAM-SHA-256+ are directly supported by
    #     Net::IMAP::SASL.  New authenticators can easily be added for any other
    #     <tt>SCRAM-*</tt> mechanism if the digest algorithm is supported by
    #     OpenSSL::Digest.
    #
    # +XOAUTH2+::
    #     See XOAuth2Authenticator.
    #
    #     Login using a username and an OAuth2 access token.  Non-standard and
    #     obsoleted by +OAUTHBEARER+, but widely supported.
    #
    # See the {SASL mechanism
    # registry}[https://www.iana.org/assignments/sasl-mechanisms/sasl-mechanisms.xhtml]
    # for a list of all SASL mechanisms and their specifications.  To register
    # new authenticators, see Authenticators.
    #
    # === Deprecated mechanisms
    #
    # <em>Obsolete mechanisms should be avoided, but are still available for
    # backwards compatibility.</em>
    #
    # >>>
    #   For +DIGEST-MD5+ see DigestMD5Authenticator.
    #
    #   For +LOGIN+, see LoginAuthenticator.
    #
    #   For +CRAM-MD5+, see CramMD5Authenticator.
    #
    # <em>Using a deprecated mechanism will print a warning.</em>
    #
    module SASL
      # Exception class for any client error detected during the authentication
      # exchange.
      #
      # When the _server_ reports an authentication failure, it will respond
      # with a protocol specific error instead, e.g: +BAD+ or +NO+ in IMAP.
      #
      # When the client encounters any error, it *must* consider the
      # authentication exchange to be unsuccessful and it might need to drop the
      # connection.  For example, if the server reports that the authentication
      # exchange was successful or the protocol does not allow additional
      # authentication attempts.
      Error = Class.new(StandardError)

      # Indicates an authentication exchange that will be or has been canceled
      # by the client, not due to any error or failure during processing.
      AuthenticationCanceled = Class.new(Error)

      # Indicates an error when processing a server challenge, e.g: an invalid
      # or unparsable challenge.  An underlying exception may be available as
      # the exception's #cause.
      AuthenticationError = Class.new(Error)

      # Indicates that authentication cannot proceed because one of the server's
      # messages has not passed integrity checks.
      AuthenticationFailed = Class.new(Error)

      # Indicates that authentication cannot proceed because one of the server's
      # ended authentication prematurely.
      class AuthenticationIncomplete < AuthenticationFailed
        # The success response from the server
        attr_reader :response

        def initialize(response, message = "authentication ended prematurely")
          super(message)
          @response = response
        end
      end

      # autoloading to avoid loading all of the regexps when they aren't used.
      sasl_stringprep_rb = File.expand_path("sasl/stringprep", __dir__)
      autoload :StringPrep,          sasl_stringprep_rb
      autoload :SASLprep,            sasl_stringprep_rb
      autoload :StringPrepError,     sasl_stringprep_rb
      autoload :ProhibitedCodepoint, sasl_stringprep_rb
      autoload :BidiStringError,     sasl_stringprep_rb

      sasl_dir = File.expand_path("sasl", __dir__)
      autoload :AuthenticationExchange,   "#{sasl_dir}/authentication_exchange"
      autoload :ClientAdapter,            "#{sasl_dir}/client_adapter"
      autoload :ProtocolAdapters,         "#{sasl_dir}/protocol_adapters"

      autoload :Authenticators,           "#{sasl_dir}/authenticators"
      autoload :GS2Header,                "#{sasl_dir}/gs2_header"
      autoload :ScramAlgorithm,           "#{sasl_dir}/scram_algorithm"

      autoload :AnonymousAuthenticator,   "#{sasl_dir}/anonymous_authenticator"
      autoload :ExternalAuthenticator,    "#{sasl_dir}/external_authenticator"
      autoload :OAuthBearerAuthenticator, "#{sasl_dir}/oauthbearer_authenticator"
      autoload :PlainAuthenticator,       "#{sasl_dir}/plain_authenticator"
      autoload :ScramAuthenticator,       "#{sasl_dir}/scram_authenticator"
      autoload :ScramSHA1Authenticator,   "#{sasl_dir}/scram_authenticator"
      autoload :ScramSHA256Authenticator, "#{sasl_dir}/scram_authenticator"
      autoload :XOAuth2Authenticator,     "#{sasl_dir}/xoauth2_authenticator"

      autoload :CramMD5Authenticator,     "#{sasl_dir}/cram_md5_authenticator"
      autoload :DigestMD5Authenticator,   "#{sasl_dir}/digest_md5_authenticator"
      autoload :LoginAuthenticator,       "#{sasl_dir}/login_authenticator"

      # Returns the default global SASL::Authenticators instance.
      def self.authenticators; @authenticators ||= Authenticators.new end

      # Delegates to <tt>registry.new</tt>  See Authenticators#new.
      def self.authenticator(*args, registry: authenticators, **kwargs, &block)
        registry.new(*args, **kwargs, &block)
      end

      # Delegates to ::authenticators.  See Authenticators#add_authenticator.
      def self.add_authenticator(...) authenticators.add_authenticator(...) end

      module_function

      # See Net::IMAP::StringPrep::SASLprep#saslprep.
      def saslprep(string, **opts)
        Net::IMAP::StringPrep::SASLprep.saslprep(string, **opts)
      end

    end
  end
end
