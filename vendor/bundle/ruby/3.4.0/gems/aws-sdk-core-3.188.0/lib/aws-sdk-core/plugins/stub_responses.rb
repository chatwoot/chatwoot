# frozen_string_literal: true

module Aws
  module Plugins
    # @api private
    class StubResponses < Seahorse::Client::Plugin

      option(:stub_responses,
        default: false,
        doc_type: 'Boolean',
        docstring: <<-DOCS)
Causes the client to return stubbed responses. By default
fake responses are generated and returned. You can specify
the response data to return or errors to raise by calling
{ClientStubs#stub_responses}. See {ClientStubs} for more information.

** Please note ** When response stubbing is enabled, no HTTP
requests are made, and retries are disabled.
        DOCS

      option(:region) do |config|
        'us-stubbed-1' if config.stub_responses
      end

      option(:credentials) do |config|
        if config.stub_responses
          Credentials.new('stubbed-akid', 'stubbed-secret')
        end
      end

      def add_handlers(handlers, config)
        handlers.add(Handler, step: :send) if config.stub_responses
      end

      def after_initialize(client)
        if client.config.stub_responses
          client.setup_stubbing
          client.handlers.remove(RetryErrors::Handler)
          client.handlers.remove(RetryErrors::LegacyHandler)
          client.handlers.remove(ClientMetricsPlugin::Handler)
          client.handlers.remove(ClientMetricsSendPlugin::LatencyHandler)
          client.handlers.remove(ClientMetricsSendPlugin::AttemptHandler)
          client.handlers.remove(Seahorse::Client::Plugins::RequestCallback::OptionHandler)
          client.handlers.remove(Seahorse::Client::Plugins::RequestCallback::ReadCallbackHandler)
        end
      end

      class Handler < Seahorse::Client::Handler

        def call(context)
          stub = context.client.next_stub(context)
          resp = Seahorse::Client::Response.new(context: context)
          async_mode = context.client.is_a? Seahorse::Client::AsyncBase
          if Hash === stub && stub[:mutex]
            stub[:mutex].synchronize { apply_stub(stub, resp, async_mode) }
          else
            apply_stub(stub, resp, async_mode)
          end

          async_mode ? Seahorse::Client::AsyncResponse.new(
            context: context, stream: context[:input_event_stream_handler].event_emitter.stream, sync_queue: Queue.new) : resp
        end

        def apply_stub(stub, response, async_mode = false)
          http_resp = response.context.http_response
          case
          when stub[:error] then signal_error(stub[:error], http_resp)
          when stub[:http] then signal_http(stub[:http], http_resp, async_mode)
          when stub[:data] then response.data = stub[:data]
          end
        end

        def signal_error(error, http_resp)
          if Exception === error
            http_resp.signal_error(error)
          else
            http_resp.signal_error(error.new)
          end
        end

        # @param [Seahorse::Client::Http::Response] stub
        # @param [Seahorse::Client::Http::Response | Seahorse::Client::Http::AsyncResponse] http_resp
        # @param [Boolean] async_mode
        def signal_http(stub, http_resp, async_mode = false)
          if async_mode
            h2_headers = stub.headers.to_h.inject([]) do |arr, (k, v)|
              arr << [k, v]
            end
            h2_headers << [":status", stub.status_code]
            http_resp.signal_headers(h2_headers)
          else
            http_resp.signal_headers(stub.status_code, stub.headers.to_h)
          end
          while chunk = stub.body.read(1024 * 1024)
            http_resp.signal_data(chunk)
          end
          stub.body.rewind
          http_resp.signal_done
        end

      end
    end
  end
end
