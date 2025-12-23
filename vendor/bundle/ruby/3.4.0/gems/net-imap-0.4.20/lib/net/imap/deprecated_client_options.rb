# frozen_string_literal: true

module Net
  class IMAP < Protocol

    # This module handles deprecated arguments to various Net::IMAP methods.
    module DeprecatedClientOptions

      # :call-seq:
      #   Net::IMAP.new(host, **options) # standard keyword options
      #   Net::IMAP.new(host, options)   # obsolete hash options
      #   Net::IMAP.new(host, port)      # obsolete port argument
      #   Net::IMAP.new(host, port, usessl, certs = nil, verify = true) # deprecated SSL arguments
      #
      # Translates Net::IMAP.new arguments for backward compatibility.
      #
      # ==== Obsolete arguments
      #
      # Use of obsolete arguments does not print a warning.  Obsolete arguments
      # will be deprecated by a future release.
      #
      # If a second positional argument is given and it is a hash (or is
      # convertible via +#to_hash+), it is converted to keyword arguments.
      #
      #     # Obsolete:
      #     Net::IMAP.new("imap.example.com", options_hash)
      #     # Use instead:
      #     Net::IMAP.new("imap.example.com", **options_hash)
      #
      # If a second positional argument is given and it is not a hash, it is
      # converted to the +port+ keyword argument.
      #     # Obsolete:
      #     Net::IMAP.new("imap.example.com", 114433)
      #     # Use instead:
      #     Net::IMAP.new("imap.example.com", port: 114433)
      #
      # ==== Deprecated arguments
      #
      # Using deprecated arguments prints a warning.  Convert to keyword
      # arguments to avoid the warning.  Deprecated arguments will be removed in
      # a future release.
      #
      # If +usessl+ is false, +certs+, and +verify+ are ignored.  When it true,
      # all three arguments are converted to the +ssl+ keyword argument.
      # Without +certs+ or +verify+, it is converted to <tt>ssl: true</tt>.
      #     # DEPRECATED:
      #     Net::IMAP.new("imap.example.com", nil, true) # => prints a warning
      #     # Use instead:
      #     Net::IMAP.new("imap.example.com", ssl: true)
      #
      # When +certs+ is a path to a directory, it is converted to <tt>ca_path:
      # certs</tt>.
      #     # DEPRECATED:
      #     Net::IMAP.new("imap.example.com", nil, true, "/path/to/certs") # => prints a warning
      #     # Use instead:
      #     Net::IMAP.new("imap.example.com", ssl: {ca_path: "/path/to/certs"})
      #
      # When +certs+ is a path to a file, it is converted to <tt>ca_file:
      # certs</tt>.
      #     # DEPRECATED:
      #     Net::IMAP.new("imap.example.com", nil, true, "/path/to/cert.pem") # => prints a warning
      #     # Use instead:
      #     Net::IMAP.new("imap.example.com", ssl: {ca_file: "/path/to/cert.pem"})
      #
      # When +verify+ is +false+, it is converted to <tt>verify_mode:
      # OpenSSL::SSL::VERIFY_NONE</tt>.
      #     # DEPRECATED:
      #     Net::IMAP.new("imap.example.com", nil, true, nil, false) # => prints a warning
      #     # Use instead:
      #     Net::IMAP.new("imap.example.com", ssl: {verify_mode: OpenSSL::SSL::VERIFY_NONE})
      #
      def initialize(host, port_or_options = nil, *deprecated, **options)
        if port_or_options.nil? && deprecated.empty?
          super host, **options
        elsif options.any?
          # Net::IMAP.new(host, *__invalid__, **options)
          raise ArgumentError, "Do not combine deprecated and keyword arguments"
        elsif port_or_options.respond_to?(:to_hash) and deprecated.any?
          # Net::IMAP.new(host, options, *__invalid__)
          raise ArgumentError, "Do not use deprecated SSL params with options hash"
        elsif port_or_options.respond_to?(:to_hash)
          super host, **Hash.try_convert(port_or_options)
        elsif deprecated.empty?
          super host, port: port_or_options
        elsif deprecated.shift
          warn "DEPRECATED: Call Net::IMAP.new with keyword options", uplevel: 1
          super host, port: port_or_options, ssl: create_ssl_params(*deprecated)
        else
          warn "DEPRECATED: Call Net::IMAP.new with keyword options", uplevel: 1
          super host, port: port_or_options, ssl: false
        end
      end

      # :call-seq:
      #   starttls(**options) # standard
      #   starttls(options = {}) # obsolete
      #   starttls(certs = nil, verify = true) # deprecated
      #
      # Translates Net::IMAP#starttls arguments for backward compatibility.
      #
      # Support for +certs+ and +verify+ will be dropped in a future release.
      #
      # See ::new for interpretation of +certs+ and +verify+.
      def starttls(*deprecated, **options)
        if deprecated.empty?
          super(**options)
        elsif options.any?
          # starttls(*__invalid__, **options)
          raise ArgumentError, "Do not combine deprecated and keyword options"
        elsif deprecated.first.respond_to?(:to_hash) && deprecated.length > 1
          # starttls(*__invalid__, **options)
          raise ArgumentError, "Do not use deprecated verify param with options hash"
        elsif deprecated.first.respond_to?(:to_hash)
          super(**Hash.try_convert(deprecated.first))
        else
          warn "DEPRECATED: Call Net::IMAP#starttls with keyword options", uplevel: 1
          super(**create_ssl_params(*deprecated))
        end
      end

      private

      def create_ssl_params(certs = nil, verify = true)
        params = {}
        if certs
          if File.file?(certs)
            params[:ca_file] = certs
          elsif File.directory?(certs)
            params[:ca_path] = certs
          end
        end
        params[:verify_mode] =
          verify ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
        params
      end

    end
  end
end
