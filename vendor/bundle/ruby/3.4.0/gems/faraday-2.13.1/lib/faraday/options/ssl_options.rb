# frozen_string_literal: true

module Faraday
  # @!parse
  #   # SSL-related options.
  #   #
  #   # @!attribute verify
  #   #   @return [Boolean] whether to verify SSL certificates or not
  #   #
  #   # @!attribute verify_hostname
  #   #   @return [Boolean] whether to enable hostname verification on server certificates
  #   #           during the handshake or not (see https://github.com/ruby/openssl/pull/60)
  #   #
  #   # @!attribute hostname
  #   #   @return [String] Server hostname used for SNI (see https://ruby-doc.org/stdlib-2.5.1/libdoc/openssl/rdoc/OpenSSL/SSL/SSLSocket.html#method-i-hostname-3D)
  #   #
  #   # @!attribute ca_file
  #   #   @return [String] CA file
  #   #
  #   # @!attribute ca_path
  #   #   @return [String] CA path
  #   #
  #   # @!attribute verify_mode
  #   #   @return [Integer] Any `OpenSSL::SSL::` constant (see https://ruby-doc.org/stdlib-2.5.1/libdoc/openssl/rdoc/OpenSSL/SSL.html)
  #   #
  #   # @!attribute cert_store
  #   #   @return [OpenSSL::X509::Store] certificate store
  #   #
  #   # @!attribute client_cert
  #   #   @return [String, OpenSSL::X509::Certificate] client certificate
  #   #
  #   # @!attribute client_key
  #   #   @return [String, OpenSSL::PKey::RSA, OpenSSL::PKey::DSA] client key
  #   #
  #   # @!attribute certificate
  #   #   @return [OpenSSL::X509::Certificate] certificate (Excon only)
  #   #
  #   # @!attribute private_key
  #   #   @return [OpenSSL::PKey::RSA, OpenSSL::PKey::DSA] private key (Excon only)
  #   #
  #   # @!attribute verify_depth
  #   #   @return [Integer] maximum depth for the certificate chain verification
  #   #
  #   # @!attribute version
  #   #   @return [String, Symbol] SSL version (see https://ruby-doc.org/stdlib-2.5.1/libdoc/openssl/rdoc/OpenSSL/SSL/SSLContext.html#method-i-ssl_version-3D)
  #   #
  #   # @!attribute min_version
  #   #   @return [String, Symbol] minimum SSL version (see https://ruby-doc.org/stdlib-2.5.1/libdoc/openssl/rdoc/OpenSSL/SSL/SSLContext.html#method-i-min_version-3D)
  #   #
  #   # @!attribute max_version
  #   #   @return [String, Symbol] maximum SSL version (see https://ruby-doc.org/stdlib-2.5.1/libdoc/openssl/rdoc/OpenSSL/SSL/SSLContext.html#method-i-max_version-3D)
  #   #
  #   # @!attribute ciphers
  #   #   @return [String] cipher list in OpenSSL format (see https://ruby-doc.org/stdlib-2.5.1/libdoc/openssl/rdoc/OpenSSL/SSL/SSLContext.html#method-i-ciphers-3D)
  #   class SSLOptions < Options; end
  SSLOptions = Options.new(:verify, :verify_hostname, :hostname,
                           :ca_file, :ca_path, :verify_mode,
                           :cert_store, :client_cert, :client_key,
                           :certificate, :private_key, :verify_depth,
                           :version, :min_version, :max_version, :ciphers) do
    # @return [Boolean] true if should verify
    def verify?
      verify != false
    end

    # @return [Boolean] true if should not verify
    def disable?
      !verify?
    end

    # @return [Boolean] true if should verify_hostname
    def verify_hostname?
      verify_hostname != false
    end
  end
end
