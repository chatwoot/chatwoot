# frozen_string_literal: true

require 'net/http'
require_relative '../../../transport/ext'
require_relative 'net'

module Datadog
  module Core
    module Transport
      module HTTP
        module Adapters
          # Adapter for Unix sockets
          class UnixSocket < Adapters::Net
            attr_reader \
              :filepath, # DEV(1.0): Rename to `uds_path`
              :timeout

            alias_method :uds_path, :filepath

            # @deprecated Positional parameters are deprecated. Use named parameters instead.
            # rubocop:disable Lint/MissingSuper
            def initialize(uds_path = nil, **options)
              @filepath = uds_path || options.fetch(:uds_path)
              @timeout = options[:timeout] || Datadog::Core::Transport::Ext::UnixSocket::DEFAULT_TIMEOUT_SECONDS
            end
            # rubocop:enable Lint/MissingSuper

            def self.build(agent_settings)
              new(
                uds_path: agent_settings.uds_path,
                timeout: agent_settings.timeout_seconds,
              )
            end

            def open(&block)
              # Open connection
              connection = HTTP.new(
                uds_path,
                read_timeout: timeout,
                continue_timeout: timeout
              )

              connection.start(&block)
            end

            def url
              "http+unix://#{uds_path}?timeout=#{timeout}"
            end

            # Re-implements Net:HTTP with underlying Unix socket
            class HTTP < ::Net::HTTP
              DEFAULT_TIMEOUT = 30

              attr_reader \
                :filepath, # DEV(1.0): Rename to `uds_path`
                :unix_socket

              alias_method :uds_path, :filepath

              def initialize(uds_path, options = {})
                super('localhost', 80)
                @filepath = uds_path
                @read_timeout = options.fetch(:read_timeout, DEFAULT_TIMEOUT)
                @continue_timeout = options.fetch(:continue_timeout, DEFAULT_TIMEOUT)
                @debug_output = options[:debug_output] if options.key?(:debug_output)
              end

              def connect
                @unix_socket = UNIXSocket.open(uds_path)
                @socket = ::Net::BufferedIO.new(@unix_socket).tap do |socket|
                  socket.read_timeout = @read_timeout
                  socket.continue_timeout = @continue_timeout
                  socket.debug_output = @debug_output
                end
                on_connect
              end
            end
          end
        end
      end
    end
  end
end
