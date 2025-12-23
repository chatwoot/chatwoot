# frozen_string_literal: true

require_relative '../../../instrumentation/gateway/argument'
require_relative '../../../../core/header_collection'
require_relative '../../../../tracing/client_ip'

module Datadog
  module AppSec
    module Contrib
      module Rack
        module Gateway
          # Gateway Request argument. Normalized extration of data from Rack::Request
          class Request < Instrumentation::Gateway::Argument
            attr_reader :env

            def initialize(env)
              super()
              @env = env
            end

            def request
              @request ||= ::Rack::Request.new(env)
            end

            def query
              # Downstream libddwaf expects keys and values to be extractable
              # separately so we can't use [[k, v], ...]. We also want to allow
              # duplicate keys, so we use {k => [v, ...], ...} instead, taking into
              # account that {k => [v1, v2, ...], ...} is possible for duplicate keys.
              request.query_string.split('&').each.with_object({}) do |e, hash|
                k, v = e.split('=').map { |s| CGI.unescape(s) }
                hash[k] ||= []

                hash[k] << v
              end
            end

            def method
              request.request_method
            end

            def headers
              result = request.env.each_with_object({}) do |(k, v), h|
                h[k.delete_prefix('HTTP_').tap(&:downcase!).tap { |s| s.tr!('_', '-') }] = v if k.start_with?('HTTP_')
              end

              result['content-type'] = request.content_type if request.content_type
              # Since Rack 3.1, content-length is nil if the body is empty, but we still want to send it to the WAF.
              result['content-length'] = request.content_length || '0'
              result
            end

            def url
              request.url
            end

            def fullpath
              request.fullpath
            end

            def path
              request.path
            end

            def cookies
              request.cookies
            end

            def host
              request.host
            end

            def user_agent
              request.user_agent
            end

            def remote_addr
              env['REMOTE_ADDR']
            end

            def form_hash
              # force form data processing
              request.POST if request.form_data?

              # usually Hash<String,String> but can be a more complex
              # Hash<String,String||Array||Hash> when e.g coming from JSON
              env['rack.request.form_hash']
            end

            def client_ip
              remote_ip = remote_addr
              header_collection = Datadog::Core::HeaderCollection.from_hash(headers)

              Datadog::Tracing::ClientIp.extract_client_ip(header_collection, remote_ip)
            end
          end
        end
      end
    end
  end
end
