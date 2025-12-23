# frozen_string_literal: true

begin
  require 'http/2'
rescue LoadError; end
require 'openssl'
require 'socket'

module Seahorse
  module Client
    # @api private
    module H2

      # H2 Connection build on top of `http/2` gem
      # (requires Ruby >= 2.1)
      # with TLS layer plus ALPN, requires:
      # Ruby >= 2.3 and OpenSSL >= 1.0.2
      class Connection

        OPTIONS = {
          max_concurrent_streams: 100,
          connection_timeout: 60,
          connection_read_timeout: 60,
          http_wire_trace: false,
          logger: nil,
          ssl_verify_peer: true,
          ssl_ca_bundle: nil,
          ssl_ca_directory: nil,
          ssl_ca_store: nil,
          enable_alpn: false
        }

        # chunk read size at socket
        CHUNKSIZE = 1024

        SOCKET_FAMILY = ::Socket::AF_INET

        def initialize(options = {})
          OPTIONS.each_pair do |opt_name, default_value|
            value = options[opt_name].nil? ? default_value : options[opt_name]
            instance_variable_set("@#{opt_name}", value)
          end
          @h2_client = HTTP2::Client.new(
            settings_max_concurrent_streams: max_concurrent_streams
          )
          @logger = if @http_wire_trace
            options[:logger] || Logger.new($stdout)
          end
          @chunk_size = options[:read_chunk_size] || CHUNKSIZE
          @errors = []
          @status = :ready
          @mutex = Mutex.new # connection can be shared across requests
          @socket = nil
          @socket_thread = nil
        end

        OPTIONS.keys.each do |attr_name|
          attr_reader(attr_name)
        end

        alias ssl_verify_peer? ssl_verify_peer

        attr_reader :errors

        attr_accessor :input_signal_thread

        def new_stream
          begin
            @h2_client.new_stream
          rescue => error
            raise Http2StreamInitializeError.new(error)
          end
        end

        def connect(endpoint)
          @mutex.synchronize {
            if @status == :ready
              tcp, addr = _tcp_socket(endpoint)
              debug_output("opening connection to #{endpoint.host}:#{endpoint.port} ...")
              _nonblocking_connect(tcp, addr)
              debug_output('opened')

              if endpoint.scheme == 'https'
                @socket = OpenSSL::SSL::SSLSocket.new(tcp, _tls_context)
                @socket.sync_close = true
                @socket.hostname = endpoint.host

                debug_output("starting TLS for #{endpoint.host}:#{endpoint.port} ...")
                @socket.connect
                debug_output('TLS established')
              else
                @socket = tcp
              end

              _register_h2_callbacks
              @status = :active
            elsif @status == :closed
              msg = 'Async Client HTTP2 Connection is closed, you may'\
                    ' use #new_connection to create a new HTTP2 Connection for this client'
              raise Http2ConnectionClosedError.new(msg)
            end
          }
        end

        def start(stream)
          @mutex.synchronize {
            return if @socket_thread
            @socket_thread = Thread.new do
              while @socket && !@socket.closed?
                begin
                  data = @socket.read_nonblock(@chunk_size)
                  @h2_client << data
                rescue IO::WaitReadable
                  begin
                    unless IO.select([@socket], nil, nil, connection_read_timeout)
                      self.debug_output('socket connection read time out')
                      self.close!
                    else
                      # available, retry to start reading
                      retry
                    end
                  rescue
                    # error can happen when closing the socket
                    # while it's waiting for read
                    self.close!
                  end
                rescue EOFError
                  self.close!
                rescue => error
                  self.debug_output(error.inspect)
                  @errors << error
                  self.close!
                end
              end
              @socket_thread = nil
            end
            @socket_thread.abort_on_exception = true
          }
        end

        def close!
          @mutex.synchronize {
            self.debug_output('closing connection ...')
            if @socket
              @socket.close
              @socket = nil
            end
            @status = :closed
          }
        end

        def closed?
          @status == :closed
        end

        def debug_output(msg, type = nil)
          prefix = case type
            when :send then '-> '
            when :receive then '<- '
            else
              ''
            end
          return unless @logger
          _debug_entry(prefix + msg)
        end

        private

        def _debug_entry(str)
          @logger << str
          @logger << "\n"
        end

        def _register_h2_callbacks
          @h2_client.on(:frame) do |bytes|
            if @socket.nil?
              msg = 'Connection is closed due to errors, '\
                    'you can find errors at async_client.connection.errors'
              raise Http2ConnectionClosedError.new(msg)
            else
              @socket.print(bytes)
              @socket.flush
            end
          end
          if @http_wire_trace
            @h2_client.on(:frame_sent) do |frame|
              debug_output("frame: #{frame.inspect}", :send)
            end
            @h2_client.on(:frame_received) do |frame|
              debug_output("frame: #{frame.inspect}", :receive)
            end
          end
        end

        def _tcp_socket(endpoint)
          tcp = ::Socket.new(SOCKET_FAMILY, ::Socket::SOCK_STREAM, 0)
          tcp.setsockopt(::Socket::IPPROTO_TCP, ::Socket::TCP_NODELAY, 1)

          address = ::Socket.getaddrinfo(endpoint.host, nil, SOCKET_FAMILY).first[3]
          sockaddr = ::Socket.sockaddr_in(endpoint.port, address)

          [tcp, sockaddr]
        end

        def _nonblocking_connect(tcp, addr)
          begin
            tcp.connect_nonblock(addr)
          rescue IO::WaitWritable
            unless IO.select(nil, [tcp], nil, connection_timeout)
              tcp.close
              raise
            end
            begin
              tcp.connect_nonblock(addr)
            rescue Errno::EISCONN
              # tcp socket connected, continue
            end
          end
        end

        def _tls_context
          ssl_ctx = OpenSSL::SSL::SSLContext.new(:TLSv1_2)
          if ssl_verify_peer?
            ssl_ctx.verify_mode = OpenSSL::SSL::VERIFY_PEER
            ssl_ctx.ca_file = ssl_ca_bundle ? ssl_ca_bundle : _default_ca_bundle
            ssl_ctx.ca_path = ssl_ca_directory ? ssl_ca_directory : _default_ca_directory
            ssl_ctx.cert_store = ssl_ca_store if ssl_ca_store
          else
            ssl_ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
          end
          if enable_alpn
            debug_output('enabling ALPN for TLS ...')
            ssl_ctx.alpn_protocols = ['h2']
          end
          ssl_ctx
        end

        def _default_ca_bundle
          File.exist?(OpenSSL::X509::DEFAULT_CERT_FILE) ?
            OpenSSL::X509::DEFAULT_CERT_FILE : nil
        end

        def _default_ca_directory
          Dir.exist?(OpenSSL::X509::DEFAULT_CERT_DIR) ?
            OpenSSL::X509::DEFAULT_CERT_DIR : nil
        end

      end
    end
  end
end
