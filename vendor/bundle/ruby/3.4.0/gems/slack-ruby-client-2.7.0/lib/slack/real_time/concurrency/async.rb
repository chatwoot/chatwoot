# frozen_string_literal: true
require 'async/websocket'
require 'async/notification'
require 'async/clock'

module Slack
  module RealTime
    module Concurrency
      module Async
        class Client < ::Async::WebSocket::Client
          extend ::Forwardable
          def_delegators :@driver, :on, :text, :binary, :emit
        end

        class Socket < Slack::RealTime::Socket
          attr_reader :client

          def start_sync(client)
            start_reactor(client).wait
          end

          def start_async(client)
            Thread.new do
              start_reactor(client)
            end
          end

          def start_reactor(client)
            Async do |task|
              @restart = ::Async::Notification.new

              if client.run_ping?
                @ping_task = task.async do |subtask|
                  subtask.annotate "#{client} keep-alive"

                  # The timer task will naturally exit after the driver is set to nil.
                  while @restart
                    subtask.sleep client.websocket_ping_timer
                    client.run_ping! if @restart
                  end
                end
              end

              while @restart
                @client_task&.stop

                @client_task = task.async do |subtask|
                  subtask.annotate "#{client} run-loop"
                  client.run_loop
                rescue ::Async::Wrapper::Cancelled => e
                # Will get restarted by ping worker.
                rescue StandardError => e
                  client.logger.error(subtask.to_s) { e.message }
                end

                @restart.wait
              end

              @ping_task&.stop
            end
          end

          def restart_async(_client, new_url)
            @url = new_url
            @last_message_at = current_time

            @restart&.signal
          end

          def run_async(&block)
            ::Async.run(&block)
          end

          def current_time
            ::Async::Clock.now
          end

          def connect!
            super
            run_loop
          end

          # Kill the restart/ping loop.
          def disconnect!
            super
          ensure
            if (restart = @restart)
              @restart = nil
              restart.signal
            end
          end

          # Close the socket.
          def close
            super
          ensure
            if @socket
              @socket.close
              @socket = nil
            end
          end

          def run_loop
            while @driver&.next_event
              # $stderr.puts event.inspect
            end
          end

          protected

          def build_ssl_context
            OpenSSL::SSL::SSLContext.new(:TLSv1_2_client).tap do |ctx|
              ctx.set_params(verify_mode: OpenSSL::SSL::VERIFY_PEER)
            end
          end

          def build_endpoint
            endpoint = ::Async::IO::Endpoint.tcp(addr, port)
            endpoint = ::Async::IO::SSLEndpoint.new(endpoint, ssl_context: build_ssl_context) if secure?
            endpoint
          end

          def connect_socket
            build_endpoint.connect
          end

          def connect
            @socket = connect_socket
            @driver = Client.new(@socket, url)
          end
        end
      end
    end
  end
end

if Gem::Version.new(Async::WebSocket::VERSION) >= Gem::Version.new('0.9.0')
  raise(
    "Incompatible version of async-websocket, #{Async::WebSocket::VERSION}, " \
    "use \"gem 'async-websocket', '~> 0.8.0'\"."
  )
end
