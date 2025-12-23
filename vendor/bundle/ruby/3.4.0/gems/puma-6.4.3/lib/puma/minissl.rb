# frozen_string_literal: true

begin
  require 'io/wait' unless Puma::HAS_NATIVE_IO_WAIT
rescue LoadError
end

require 'open3'
# need for Puma::MiniSSL::OPENSSL constants used in `HAS_TLS1_3`
# use require, see https://github.com/puma/puma/pull/2381
require 'puma/puma_http11'

module Puma
  module MiniSSL
    # Define constant at runtime, as it's easy to determine at built time,
    # but Puma could (it shouldn't) be loaded with an older OpenSSL version
    # @version 5.0.0
    HAS_TLS1_3 = IS_JRUBY ||
        ((OPENSSL_VERSION[/ \d+\.\d+\.\d+/].split('.').map(&:to_i) <=> [1,1,1]) != -1 &&
         (OPENSSL_LIBRARY_VERSION[/ \d+\.\d+\.\d+/].split('.').map(&:to_i) <=> [1,1,1]) !=-1)

    class Socket
      def initialize(socket, engine)
        @socket = socket
        @engine = engine
        @peercert = nil
        @reuse = nil
      end

      # @!attribute [r] to_io
      def to_io
        @socket
      end

      def closed?
        @socket.closed?
      end

      # Returns a two element array,
      # first is protocol version (SSL_get_version),
      # second is 'handshake' state (SSL_state_string)
      #
      # Used for dropping tcp connections to ssl.
      # See OpenSSL ssl/ssl_stat.c SSL_state_string for info
      # @!attribute [r] ssl_version_state
      # @version 5.0.0
      #
      def ssl_version_state
        IS_JRUBY ? [nil, nil] : @engine.ssl_vers_st
      end

      # Used to check the handshake status, in particular when a TCP connection
      # is made with TLSv1.3 as an available protocol
      # @version 5.0.0
      def bad_tlsv1_3?
        HAS_TLS1_3 && ssl_version_state == ['TLSv1.3', 'SSLERR']
      end
      private :bad_tlsv1_3?

      def readpartial(size)
        while true
          output = @engine.read
          return output if output

          data = @socket.readpartial(size)
          @engine.inject(data)
          output = @engine.read

          return output if output

          while neg_data = @engine.extract
            @socket.write neg_data
          end
        end
      end

      def engine_read_all
        output = @engine.read
        while output and additional_output = @engine.read
          output << additional_output
        end
        output
      end

      def read_nonblock(size, *_)
        # *_ is to deal with keyword args that were added
        # at some point (and being used in the wild)
        while true
          output = engine_read_all
          return output if output

          data = @socket.read_nonblock(size, exception: false)
          if data == :wait_readable || data == :wait_writable
            # It would make more sense to let @socket.read_nonblock raise
            # EAGAIN if necessary but it seems like it'll misbehave on Windows.
            # I don't have a Windows machine to debug this so I can't explain
            # exactly whats happening in that OS. Please let me know if you
            # find out!
            #
            # In the meantime, we can emulate the correct behavior by
            # capturing :wait_readable & :wait_writable and raising EAGAIN
            # ourselves.
            raise IO::EAGAINWaitReadable
          elsif data.nil?
            raise SSLError.exception "HTTP connection?" if bad_tlsv1_3?
            return nil
          end

          @engine.inject(data)
          output = engine_read_all

          return output if output

          while neg_data = @engine.extract
            @socket.write neg_data
          end
        end
      end

      def write(data)
        return 0 if data.empty?

        data_size = data.bytesize
        need = data_size

        while true
          wrote = @engine.write data

          enc_wr = +''
          while (enc = @engine.extract)
            enc_wr << enc
          end
          @socket.write enc_wr unless enc_wr.empty?

          need -= wrote

          return data_size if need == 0

          data = data.byteslice(wrote..-1)
        end
      end

      alias_method :syswrite, :write
      alias_method :<<, :write

      # This is a temporary fix to deal with websockets code using
      # write_nonblock.

      # The problem with implementing it properly
      # is that it means we'd have to have the ability to rewind
      # an engine because after we write+extract, the socket
      # write_nonblock call might raise an exception and later
      # code would pass the same data in, but the engine would think
      # it had already written the data in.
      #
      # So for the time being (and since write blocking is quite rare),
      # go ahead and actually block in write_nonblock.
      #
      def write_nonblock(data, *_)
        write data
      end

      def flush
        @socket.flush
      end

      def close
        begin
          unless @engine.shutdown
            while alert_data = @engine.extract
              @socket.write alert_data
            end
          end
        rescue IOError, SystemCallError
          Puma::Util.purge_interrupt_queue
          # nothing
        ensure
          @socket.close
        end
      end

      # @!attribute [r] peeraddr
      def peeraddr
        @socket.peeraddr
      end

      # OpenSSL is loaded in `MiniSSL::ContextBuilder` when
      # `MiniSSL::Context#verify_mode` is not `VERIFY_NONE`.
      # When `VERIFY_NONE`, `MiniSSL::Engine#peercert` is nil, regardless of
      # whether the client sends a cert.
      # @return [OpenSSL::X509::Certificate, nil]
      # @!attribute [r] peercert
      def peercert
        return @peercert if @peercert

        raw = @engine.peercert
        return nil unless raw

        @peercert = OpenSSL::X509::Certificate.new raw
      end
    end

    if IS_JRUBY
      OPENSSL_NO_SSL3 = false
      OPENSSL_NO_TLS1 = false
    end

    class Context
      attr_accessor :verify_mode
      attr_reader :no_tlsv1, :no_tlsv1_1

      def initialize
        @no_tlsv1   = false
        @no_tlsv1_1 = false
        @key = nil
        @cert = nil
        @key_pem = nil
        @cert_pem = nil
        @reuse = nil
        @reuse_cache_size = nil
        @reuse_timeout = nil
      end

      def check_file(file, desc)
        raise ArgumentError, "#{desc} file '#{file}' does not exist" unless File.exist? file
        raise ArgumentError, "#{desc} file '#{file}' is not readable" unless File.readable? file
      end

      if IS_JRUBY
        # jruby-specific Context properties: java uses a keystore and password pair rather than a cert/key pair
        attr_reader :keystore
        attr_reader :keystore_type
        attr_accessor :keystore_pass
        attr_reader :truststore
        attr_reader :truststore_type
        attr_accessor :truststore_pass
        attr_reader :cipher_suites
        attr_reader :protocols

        def keystore=(keystore)
          check_file keystore, 'Keystore'
          @keystore = keystore
        end

        def truststore=(truststore)
          # NOTE: historically truststore was assumed the same as keystore, this is kept for backwards
          # compatibility, to rely on JVM's trust defaults we allow setting `truststore = :default`
          unless truststore.eql?(:default)
            raise ArgumentError, "No such truststore file '#{truststore}'" unless File.exist?(truststore)
          end
          @truststore = truststore
        end

        def keystore_type=(type)
          raise ArgumentError, "Invalid keystore type: #{type.inspect}" unless ['pkcs12', 'jks', nil].include?(type)
          @keystore_type = type
        end

        def truststore_type=(type)
          raise ArgumentError, "Invalid truststore type: #{type.inspect}" unless ['pkcs12', 'jks', nil].include?(type)
          @truststore_type = type
        end

        def cipher_suites=(list)
          list = list.split(',').map(&:strip) if list.is_a?(String)
          @cipher_suites = list
        end

        # aliases for backwards compatibility
        alias_method :ssl_cipher_list, :cipher_suites
        alias_method :ssl_cipher_list=, :cipher_suites=

        def protocols=(list)
          list = list.split(',').map(&:strip) if list.is_a?(String)
          @protocols = list
        end

        def check
          raise "Keystore not configured" unless @keystore
          # @truststore defaults to @keystore due backwards compatibility
        end

      else
        # non-jruby Context properties
        attr_reader :key
        attr_reader :key_password_command
        attr_reader :cert
        attr_reader :ca
        attr_reader :cert_pem
        attr_reader :key_pem
        attr_accessor :ssl_cipher_filter
        attr_accessor :verification_flags

        attr_reader :reuse, :reuse_cache_size, :reuse_timeout

        def key=(key)
          check_file key, 'Key'
          @key = key
        end

        def key_password_command=(key_password_command)
          @key_password_command = key_password_command
        end

        def cert=(cert)
          check_file cert, 'Cert'
          @cert = cert
        end

        def ca=(ca)
          check_file ca, 'ca'
          @ca = ca
        end

        def cert_pem=(cert_pem)
          raise ArgumentError, "'cert_pem' is not a String" unless cert_pem.is_a? String
          @cert_pem = cert_pem
        end

        def key_pem=(key_pem)
          raise ArgumentError, "'key_pem' is not a String" unless key_pem.is_a? String
          @key_pem = key_pem
        end

        def check
          raise "Key not configured" if @key.nil? && @key_pem.nil?
          raise "Cert not configured" if @cert.nil? && @cert_pem.nil?
        end

        # Executes the command to return the password needed to decrypt the key.
        def key_password
          raise "Key password command not configured" if @key_password_command.nil?

          stdout_str, stderr_str, status = Open3.capture3(@key_password_command)

          return stdout_str.chomp if status.success?

          raise "Key password failed with code #{status.exitstatus}: #{stderr_str}"
        end

        # Controls session reuse.  Allowed values are as follows:
        # * 'off' - matches the behavior of Puma 5.6 and earlier.  This is included
        #   in case reuse 'on' is made the default in future Puma versions.
        # * 'dflt' - sets session reuse on, with OpenSSL default cache size of
        #   20k and default timeout of 300 seconds.
        # * 's,t' - where s and t are integer strings, for size and timeout.
        # * 's' - where s is an integer strings for size.
        # * ',t' - where t is an integer strings for timeout.
        #
        def reuse=(reuse_str)
          case reuse_str
          when 'off'
            @reuse = nil
          when 'dflt'
            @reuse = true
          when /\A\d+\z/
            @reuse = true
            @reuse_cache_size = reuse_str.to_i
          when /\A\d+,\d+\z/
            @reuse = true
            size, time = reuse_str.split ','
            @reuse_cache_size = size.to_i
            @reuse_timeout = time.to_i
          when /\A,\d+\z/
            @reuse = true
            @reuse_timeout = reuse_str.delete(',').to_i
          end
        end
      end

      # disables TLSv1
      # @!attribute [w] no_tlsv1=
      def no_tlsv1=(tlsv1)
        raise ArgumentError, "Invalid value of no_tlsv1=" unless ['true', 'false', true, false].include?(tlsv1)
        @no_tlsv1 = tlsv1
      end

      # disables TLSv1 and TLSv1.1.  Overrides `#no_tlsv1=`
      # @!attribute [w] no_tlsv1_1=
      def no_tlsv1_1=(tlsv1_1)
        raise ArgumentError, "Invalid value of no_tlsv1_1=" unless ['true', 'false', true, false].include?(tlsv1_1)
        @no_tlsv1_1 = tlsv1_1
      end

    end

    VERIFY_NONE = 0
    VERIFY_PEER = 1
    VERIFY_FAIL_IF_NO_PEER_CERT = 2

    # https://github.com/openssl/openssl/blob/master/include/openssl/x509_vfy.h.in
    # /* Certificate verify flags */
    VERIFICATION_FLAGS = {
      "USE_CHECK_TIME"       => 0x2,
      "CRL_CHECK"            => 0x4,
      "CRL_CHECK_ALL"        => 0x8,
      "IGNORE_CRITICAL"      => 0x10,
      "X509_STRICT"          => 0x20,
      "ALLOW_PROXY_CERTS"    => 0x40,
      "POLICY_CHECK"         => 0x80,
      "EXPLICIT_POLICY"      => 0x100,
      "INHIBIT_ANY"          => 0x200,
      "INHIBIT_MAP"          => 0x400,
      "NOTIFY_POLICY"        => 0x800,
      "EXTENDED_CRL_SUPPORT" => 0x1000,
      "USE_DELTAS"           => 0x2000,
      "CHECK_SS_SIGNATURE"   => 0x4000,
      "TRUSTED_FIRST"        => 0x8000,
      "SUITEB_128_LOS_ONLY"  => 0x10000,
      "SUITEB_192_LOS"       => 0x20000,
      "SUITEB_128_LOS"       => 0x30000,
      "PARTIAL_CHAIN"        => 0x80000,
      "NO_ALT_CHAINS"        => 0x100000,
      "NO_CHECK_TIME"        => 0x200000
    }.freeze

    class Server
      def initialize(socket, ctx)
        @socket = socket
        @ctx = ctx
        @eng_ctx = IS_JRUBY ? @ctx : SSLContext.new(ctx)
      end

      def accept
        @ctx.check
        io = @socket.accept
        engine = Engine.server @eng_ctx
        Socket.new io, engine
      end

      def accept_nonblock
        @ctx.check
        io = @socket.accept_nonblock
        engine = Engine.server @eng_ctx
        Socket.new io, engine
      end

      # @!attribute [r] to_io
      def to_io
        @socket
      end

      # @!attribute [r] addr
      # @version 5.0.0
      def addr
        @socket.addr
      end

      def close
        @socket.close unless @socket.closed?       # closed? call is for Windows
      end

      def closed?
        @socket.closed?
      end
    end
  end
end
