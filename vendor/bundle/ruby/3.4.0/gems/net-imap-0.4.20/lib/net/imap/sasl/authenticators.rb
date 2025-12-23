# frozen_string_literal: true

module Net::IMAP::SASL

  # Registry for SASL authenticators
  #
  # Registered authenticators must respond to +#new+ or +#call+ (e.g. a class or
  # a proc), receiving any credentials and options and returning an
  # authenticator instance. The returned object represents a single
  # authentication exchange and <em>must not</em> be reused for multiple
  # authentication attempts.
  #
  # An authenticator instance object must respond to +#process+, receiving the
  # server's challenge and returning the client's response.  Optionally, it may
  # also respond to +#initial_response?+ and +#done?+.  When
  # +#initial_response?+ returns +true+, +#process+ may be called the first
  # time with +nil+.  When +#done?+ returns +false+, the exchange is incomplete
  # and an exception should be raised if the exchange terminates prematurely.
  #
  # See the source for PlainAuthenticator, XOAuth2Authenticator, and
  # ScramSHA1Authenticator for examples.
  class Authenticators

    # Create a new Authenticators registry.
    #
    # This class is usually not instantiated directly.  Use SASL.authenticators
    # to reuse the default global registry.
    #
    # When +use_defaults+ is +false+, the registry will start empty.  When
    # +use_deprecated+ is +false+, deprecated authenticators will not be
    # included with the defaults.
    def initialize(use_defaults: true, use_deprecated: true)
      @authenticators = {}
      return unless use_defaults
      add_authenticator "Anonymous"
      add_authenticator "External"
      add_authenticator "OAuthBearer"
      add_authenticator "Plain"
      add_authenticator "Scram-SHA-1"
      add_authenticator "Scram-SHA-256"
      add_authenticator "XOAuth2"
      return unless use_deprecated
      add_authenticator "Login"      # deprecated
      add_authenticator "Cram-MD5"   # deprecated
      add_authenticator "Digest-MD5" # deprecated
    end

    # Returns the names of all registered SASL mechanisms.
    def names; @authenticators.keys end

    # :call-seq:
    #   add_authenticator(mechanism)
    #   add_authenticator(mechanism, authenticator_class)
    #   add_authenticator(mechanism, authenticator_proc)
    #
    # Registers an authenticator for #authenticator to use.  +mechanism+ is the
    # name of the
    # {SASL mechanism}[https://www.iana.org/assignments/sasl-mechanisms/sasl-mechanisms.xhtml]
    # implemented by +authenticator_class+ (for instance, <tt>"PLAIN"</tt>).
    #
    # If +mechanism+ refers to an existing authenticator,
    # the old authenticator will be replaced.
    #
    # When only a single argument is given, the authenticator class will be
    # lazily loaded from <tt>Net::IMAP::SASL::#{name}Authenticator</tt> (case is
    # preserved and non-alphanumeric characters are removed..
    def add_authenticator(name, authenticator = nil)
      key = -name.to_s.upcase.tr(?_, ?-)
      authenticator ||= begin
        class_name = "#{name.gsub(/[^a-zA-Z0-9]/, "")}Authenticator".to_sym
        auth_class = nil
        ->(*creds, **props, &block) {
          auth_class ||= Net::IMAP::SASL.const_get(class_name)
          auth_class.new(*creds, **props, &block)
        }
      end
      @authenticators[key] = authenticator
    end

    # Removes the authenticator registered for +name+
    def remove_authenticator(name)
      key = -name.to_s.upcase.tr(?_, ?-)
      @authenticators.delete(key)
    end

    def mechanism?(name)
      key = -name.to_s.upcase.tr(?_, ?-)
      @authenticators.key?(key)
    end

    # :call-seq:
    #   authenticator(mechanism, ...) -> auth_session
    #
    # Builds an authenticator instance using the authenticator registered to
    # +mechanism+.  The returned object represents a single authentication
    # exchange and <em>must not</em> be reused for multiple authentication
    # attempts.
    #
    # All arguments (except +mechanism+) are forwarded to the registered
    # authenticator's +#new+ or +#call+ method.  Each authenticator must
    # document its own arguments.
    #
    # [Note]
    #   This method is intended for internal use by connection protocol code
    #   only.  Protocol client users should see refer to their client's
    #   documentation, e.g. Net::IMAP#authenticate.
    def authenticator(mechanism, ...)
      key = -mechanism.to_s.upcase.tr(?_, ?-)
      auth = @authenticators.fetch(key) do
        raise ArgumentError, 'unknown auth type - "%s"' % key
      end
      auth.respond_to?(:new) ? auth.new(...) : auth.call(...)
    end
    alias new authenticator

  end

end
