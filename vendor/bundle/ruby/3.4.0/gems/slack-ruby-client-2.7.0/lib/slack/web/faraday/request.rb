# frozen_string_literal: true
module Slack
  module Web
    module Faraday
      module Request
        def get(path, options = {})
          request(:get, path, options)
        end

        def post(path, options = {})
          request(:post, path, options)
        end

        def put(path, options = {})
          request(:put, path, options)
        end

        def delete(path, options = {})
          request(:delete, path, options)
        end

        private

        def request(method, path, options)
          response = connection.send(method) do |request|
            case method
            when :get, :delete
              request.url(path, options)
            when :post, :put
              request.path = path
              options.compact! if options.respond_to? :compact
              request.body = options unless options.empty?
            end
            request.headers['Authorization'] = "Bearer #{token}" if token

            request.options.merge!(options.delete(:request)) if options.key?(:request)
          end
          response.body
        rescue ::Faraday::ParsingError => e
          raise Slack::Web::Api::Errors::ParsingError, e.response
        end
      end
    end
  end
end
